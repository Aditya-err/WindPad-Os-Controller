package com.windpad.app

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ParcelUuid
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Timer
import java.util.TimerTask

class BtHidForegroundService : Service() {

    companion object {
        const val ACTION_START = "ACTION_START_FOREGROUND"
        const val ACTION_STOP = "ACTION_STOP_FOREGROUND"
        const val ACTION_DISCONNECT = "ACTION_DISCONNECT"
        const val NOTIFICATION_ID = 101

        @SuppressLint("StaticFieldLeak")
        var instance: BtHidForegroundService? = null
    }

    private var wakeLock: PowerManager.WakeLock? = null

    private var hidDevice: BluetoothHidDevice? = null
    var hostDevice: BluetoothDevice? = null
    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var bleAdvertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null
    private var isAdvertising = false

    var onStateChanged: ((String, String?, String?) -> Unit)? = null

    private var userExplicitlyDisconnected = false
    private val reconnectHandler = Handler(Looper.getMainLooper())
    private var reconnectRunnable: Runnable? = null
    private var pingTimer: Timer? = null

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_ON || intent?.action == Intent.ACTION_USER_PRESENT) {
                if (hostDevice == null && !userExplicitlyDisconnected) {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    val mac = prefs.getString("last_device_mac", "")
                    if (!mac.isNullOrEmpty()) {
                        reconnectLastDevice(mac)
                    }
                }
            }
        }
    }

    private val btStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                if (state == BluetoothAdapter.STATE_TURNING_OFF || state == BluetoothAdapter.STATE_OFF) {
                    Log.d("BtHidService", "Bluetooth OFF: cancelling reconnect and clearing connection")
                    cancelAutoReconnect()
                    stopBleAdvertising()
                    hostDevice = null
                    stopPingTimer()
                    onStateChanged?.invoke("onDisconnected", null, null)
                    updateNotification(null)
                } else if (state == BluetoothAdapter.STATE_ON) {
                    Log.d("BtHidService", "Bluetooth ON: re-initializing profile and auto-connecting")
                    userExplicitlyDisconnected = false
                    initProfile()
                }
            }
        }
    }

    private val pairingReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action == BluetoothDevice.ACTION_PAIRING_REQUEST) {
                val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE) ?: return
                try {
                    val method = device.javaClass.getMethod("setPairingConfirmation", Boolean::class.javaPrimitiveType)
                    method.invoke(device, true)
                    abortBroadcast()
                    Log.d("BtHidService", "Auto-confirmed pairing for ${device.name}")
                } catch (e: Exception) {
                    try {
                        val method = device.javaClass.getMethod("setPairingConfirmation", Boolean::class.java)
                        method.invoke(device, true)
                        abortBroadcast()
                        Log.d("BtHidService", "Auto-confirmed pairing for ${device.name} (boxed)")
                    } catch (ex: Exception) {
                        Log.e("BtHidService", "setPairingConfirmation failed", ex)
                    }
                }
            }
        }
    }

    private val hidServiceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hidDevice = proxy as BluetoothHidDevice
                registerApp()
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                hidDevice = null
            }
        }
    }

    private val hidCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            super.onAppStatusChanged(pluggedDevice, registered)
            if (registered) {
                Log.d("BtHidService", "HID app registered — checking connections")
                checkAlreadyConnectedDevices()
                if (!userExplicitlyDisconnected) {
                    autoConnectLastDevice()
                }
                if (hostDevice == null) {
                    startBleAdvertising()
                }
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            super.onConnectionStateChanged(device, state)
            if (state == BluetoothProfile.STATE_CONNECTED) {
                hostDevice = device
                userExplicitlyDisconnected = false
                cancelAutoReconnect()
                stopBleAdvertising()
                Log.d("BtHidService", "Connected to ${device?.name} (${device?.address})")
                // Save last connected
                device?.address?.let { addr ->
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("last_device_mac", addr).apply()
                }
                onStateChanged?.invoke("onConnected", device?.name, device?.address)
                updateNotification(device?.name ?: "Unknown Device")
                showSystemAlert("Windpad Connected", "Connected to ${device?.name ?: "Bluetooth Device"}")
                startPingTimer()
            } else if (state == BluetoothProfile.STATE_CONNECTING) {
                onStateChanged?.invoke("onConnecting", device?.name, device?.address)
            } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                val lastDevName = hostDevice?.name ?: "Device"
                hostDevice = null
                stopPingTimer()
                onStateChanged?.invoke("onDisconnected", null, null)
                updateNotification(null)
                if (!userExplicitlyDisconnected) {
                    showSystemAlert("Windpad Disconnected", "Disconnected from $lastDevName")
                }

                // Resume BLE advertising so Smart TVs & hosts can discover and reconnect
                startBleAdvertising()

                // Persistent auto-reconnect: keep connection alive unless user explicitly requested disconnect or BT is off
                if (!userExplicitlyDisconnected) {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    val lastMac = prefs.getString("last_device_mac", "") ?: device?.address ?: ""
                    if (lastMac.isNotEmpty()) {
                        Log.d("BtHidService", "Connection dropped; starting persistent auto-reconnect to $lastMac")
                        schedulePersistentReconnect(lastMac)
                    }
                } else {
                    Log.d("BtHidService", "User explicitly disconnected; not reconnecting automatically")
                }
            }
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            super.onGetReport(device, type, id, bufferSize)
            if (device == null) return
            val emptyReport = when (id.toInt()) {
                1 -> byteArrayOf(0, 0, 0, 0)
                2 -> ByteArray(8)
                3 -> ByteArray(2)
                else -> ByteArray(0)
            }
            try {
                hidDevice?.replyReport(device, type, id, emptyReport)
            } catch (e: Exception) {
                Log.e("BtHidService", "replyReport failed", e)
            }
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
            super.onSetReport(device, type, id, data)
            if (device == null) return
            try {
                hidDevice?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
            } catch (e: Exception) {
                Log.e("BtHidService", "reportError onSetReport failed", e)
            }
        }

        override fun onSetProtocol(device: BluetoothDevice?, protocol: Byte) {
            super.onSetProtocol(device, protocol)
            if (device == null) return
            try {
                hidDevice?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
            } catch (e: Exception) {
                Log.e("BtHidService", "reportError onSetProtocol failed", e)
            }
        }

        override fun onVirtualCableUnplug(device: BluetoothDevice?) {
            super.onVirtualCableUnplug(device)
            Log.d("BtHidService", "Virtual cable unplugged by host: ${device?.name}")
            hostDevice = null
            stopPingTimer()
            onStateChanged?.invoke("onDisconnected", null, null)
            updateNotification(null)
            startBleAdvertising()
        }
    }

    private fun schedulePersistentReconnect(mac: String) {
        cancelAutoReconnect()
        if (userExplicitlyDisconnected || mac.isEmpty()) return
        reconnectRunnable = object : Runnable {
            override fun run() {
                if (hostDevice == null && !userExplicitlyDisconnected && adapter?.isEnabled == true) {
                    Log.d("BtHidService", "Attempting background auto-reconnect to $mac")
                    reconnectLastDevice(mac)
                    reconnectHandler.postDelayed(this, 8000)
                }
            }
        }
        reconnectHandler.postDelayed(reconnectRunnable!!, 4000)
    }

    fun cancelAutoReconnect() {
        reconnectRunnable?.let { reconnectHandler.removeCallbacks(it) }
        reconnectRunnable = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d("BtHidService", "Service Created")
        startForegroundServiceWithNotification(null)
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_ON)
        filter.addAction(Intent.ACTION_USER_PRESENT)
        registerReceiver(screenReceiver, filter)
        
        val btFilter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        registerReceiver(btStateReceiver, btFilter)

        // Intercept pairing requests for Just Works
        val pairingFilter = IntentFilter(BluetoothDevice.ACTION_PAIRING_REQUEST)
        pairingFilter.priority = IntentFilter.SYSTEM_HIGH_PRIORITY
        registerReceiver(pairingReceiver, pairingFilter)
        
        acquireWakeLock()
        initProfile()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                disconnect()
                stopWakeLock()
                stopForeground(true)
                stopSelf()
            }
            ACTION_DISCONNECT -> {
                disconnect()
            }
        }
        return START_STICKY
    }

    private fun startForegroundServiceWithNotification(deviceName: String?) {
        val channelId = "windpad_bt_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Bluetooth HID Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val openAppIntent = Intent(this, MainActivity::class.java)
        var openAppPendingIntent: PendingIntent? = null
        try {
            openAppPendingIntent = PendingIntent.getActivity(
                this, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } catch (e: Exception) {}

        val disconnectIntent = Intent(this, BtHidForegroundService::class.java).apply {
            action = ACTION_DISCONNECT
        }
        var disconnectPendingIntent: PendingIntent? = null
        try {
            disconnectPendingIntent = PendingIntent.getService(
                this, 1, disconnectIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } catch (e: Exception) {}

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            
        if (openAppPendingIntent != null) builder.setContentIntent(openAppPendingIntent)
        
        if (deviceName != null) {
            builder.setContentTitle("Windpad Connected")
                .setContentText("Connected to $deviceName")
            if (disconnectPendingIntent != null) {
                builder.addAction(0, "Disconnect", disconnectPendingIntent)
            }
        } else {
            builder.setContentTitle("Windpad Background Service")
                .setContentText("Ready to connect via Bluetooth")
        }

        try {
            startForeground(NOTIFICATION_ID, builder.build())
        } catch(e: Exception) {
            Log.e("BtHid", "Foreground Exception", e)
        }
    }

    private fun updateNotification(deviceName: String?) {
        startForegroundServiceWithNotification(deviceName)
    }

    fun showSystemAlert(title: String, message: String, notificationId: Int = 105) {
        try {
            val channelId = "windpad_system_alerts"
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "WindPad Notifications",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "WindPad System Notifications"
                    enableVibration(true)
                    setShowBadge(true)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }

            val openAppIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                notificationId,
                openAppIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            val builder = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            notificationManager.notify(notificationId, builder.build())
        } catch (e: Exception) {
            Log.e("BtHidService", "showSystemAlert error", e)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "windpad:btlock")
            wakeLock?.acquire()
        }
    }

    private fun stopWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null
    }

    private fun startPingTimer() {
        stopPingTimer()
        pingTimer = Timer()
        pingTimer?.schedule(object : TimerTask() {
            override fun run() {
                sendMouseReport(0, 0, 0, 0)
            }
        }, 10000, 10000)
    }

    private fun stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = null
    }

    fun initProfile() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_CONNECT) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                return
            }
        }
        adapter?.getProfileProxy(this, hidServiceListener, BluetoothProfile.HID_DEVICE)
    }

    @SuppressLint("MissingPermission")
    private fun registerApp() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_CONNECT) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                return
            }
        }
        try {
            // Force legacy pairing mode, Just Works
            try {
                val method = adapter?.javaClass?.getDeclaredMethod("setIoCapability", Int::class.java)
                method?.isAccessible = true
                method?.invoke(adapter, 3) // 3 = IO_CAPABILITY_NOINPUTNOOUTPUT = Just Works
                Log.d("BtHidService", "Set IO Capability to NOINPUTNOOUTPUT")
            } catch (e: Exception) {
                Log.e("BtHidService", "Failed to set IO capability", e)
            }
            
            val sdpSettings = BluetoothHidDeviceAppSdpSettings(
                "Windpad Controller",
                "Windpad BT HID",
                "Windpad",
                BluetoothHidDevice.SUBCLASS1_COMBO,
                HidReportDescriptor.MOUSE_DESCRIPTOR + HidReportDescriptor.KEYBOARD_DESCRIPTOR + HidReportDescriptor.CONSUMER_DESCRIPTOR
            )
            val qosOut = BluetoothHidDeviceAppQosSettings(
                BluetoothHidDeviceAppQosSettings.SERVICE_BEST_EFFORT,
                800, 9, 0, 11250, BluetoothHidDeviceAppQosSettings.MAX
            )
            // inQos = null for no auth
            hidDevice?.registerApp(sdpSettings, null, qosOut, mainExecutor, hidCallback)
        } catch (e: SecurityException) {
            Log.e("BtHidService", "Permission denied for registerApp", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun sendMouseReport(buttons: Byte, dx: Byte, dy: Byte, scroll: Byte) {
        val report = byteArrayOf(buttons, dx, dy, scroll)
        hostDevice?.let { device ->
            hidDevice?.sendReport(device, 1, report)
        }
    }

    @SuppressLint("MissingPermission")
    fun sendKeyboardReport(modifier: Byte, keys: ByteArray) {
        val report = ByteArray(8)
        report[0] = modifier
        report[1] = 0x00 // Reserved
        for (i in 0 until minOf(keys.size, 6)) {
            report[i + 2] = keys[i]
        }
        hostDevice?.let { device ->
            hidDevice?.sendReport(device, 2, report)
        }
    }

    @SuppressLint("MissingPermission")
    fun sendMediaReport(keys: ByteArray) {
        val report = ByteArray(2)
        if (keys.isNotEmpty()) {
            report[0] = keys[0]
            if (keys.size > 1) {
                report[1] = keys[1]
            }
        }
        hostDevice?.let { device ->
            hidDevice?.sendReport(device, 3, report)
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        userExplicitlyDisconnected = true
        cancelAutoReconnect()
        stopBleAdvertising()
        hostDevice?.let { device ->
            adapter?.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
                 override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                     val method = proxy.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                     if (method != null) {
                         method.invoke(proxy, device)
                     }
                 }
                 override fun onServiceDisconnected(profile: Int) {}
            }, BluetoothProfile.HID_DEVICE)
        }
        // hidDevice?.unregisterApp() removed to allow instant reconnect
        hostDevice = null
        stopPingTimer()
        onStateChanged?.invoke("onDisconnected", null, null)
        updateNotification(null)
    }

    @SuppressLint("MissingPermission")
    fun reconnectLastDevice(mac: String) {
        if (mac.isEmpty()) return
        val device = adapter?.getRemoteDevice(mac)
        if (device != null && hidDevice != null) {
            if (device.bondState == BluetoothDevice.BOND_BONDED) {
                val method = hidDevice?.javaClass?.getMethod("connect", BluetoothDevice::class.java)
                if (method != null) {
                    method.invoke(hidDevice, device)
                }
            } else {
                Log.d("BtHidService", "Device not bonded, ignoring auto reconnect")
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun checkAlreadyConnectedDevices() {
        try {
            val connected = hidDevice?.getDevicesMatchingConnectionStates(
                intArrayOf(BluetoothProfile.STATE_CONNECTED)
            ) ?: emptyList()
            if (connected.isNotEmpty()) {
                val device = connected[0]
                hostDevice = device
                Log.d("BtHidService", "Already connected: ${device.name}")
                onStateChanged?.invoke("onConnected", device.name, device.address)
                updateNotification(device.name ?: "Device")
                startPingTimer()
            }
        } catch (e: Exception) {
            Log.e("BtHidService", "checkAlreadyConnected: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun autoConnectLastDevice() {
        val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
        val lastMac = prefs.getString("last_device_mac", null) ?: return
        if (hostDevice != null) return // already connected
        val target = adapter?.bondedDevices?.find { it.address == lastMac } ?: return
        Log.d("BtHidService", "Auto-connecting last device: ${target.name}")
        try {
            hidDevice?.connect(target)
        } catch (e: Exception) {
            Log.e("BtHidService", "autoConnectLast: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun tryConnectBondedDevices() {
        if (hostDevice != null) return // already connected
        val bonded = adapter?.bondedDevices ?: return
        for (device in bonded) {
            Log.d("BtHidService", "Trying bonded: ${device.name}")
            try {
                hidDevice?.connect(device)
            } catch (e: Exception) {
                Log.e("BtHidService", "tryBonded: ${e.message}")
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun checkAndSyncConnection(mac: String) {
        val device = adapter?.getRemoteDevice(mac)
        if (hidDevice == null) {
            initProfile()
            if (mac.isNotEmpty()) {
               Handler(Looper.getMainLooper()).postDelayed({ reconnectLastDevice(mac) }, 1000)
            }
            return
        }
        
        if (device != null) {
            val state = hidDevice?.getConnectionState(device)
            if (state == BluetoothProfile.STATE_CONNECTED) {
                hostDevice = device
                onStateChanged?.invoke("onConnected", device.name, device.address)
                updateNotification(device.name)
            } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                reconnectLastDevice(mac)
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun startBleAdvertising() {
        if (isAdvertising) return
        if (adapter == null || !adapter.isEnabled) return
        cancelAutoReconnect()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_ADVERTISE) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                Log.w("BtHidService", "BLUETOOTH_ADVERTISE permission not granted")
                return
            }
        }

        try {
            bleAdvertiser = adapter.bluetoothLeAdvertiser
            if (bleAdvertiser == null) {
                Log.w("BtHidService", "BluetoothLeAdvertiser not available on this device")
                return
            }

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
                .setConnectable(true)
                .setTimeout(0)
                .build()

            // Primary advert: ONLY Service UUID 0x1812 (BLE HID) - fits cleanly within 31-byte legacy BLE limit
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addServiceUuid(ParcelUuid.fromString("00001812-0000-1000-8000-00805f9b34fb"))
                .build()

            // Scan response: contains full device name so TV UI displays device name
            val scanResponse = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .build()

            advertiseCallback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    super.onStartSuccess(settingsInEffect)
                    isAdvertising = true
                    Log.d("BtHidService", "BLE HID Advertising active (UUID: 0x1812) - Smart TV discoverable")
                }

                override fun onStartFailure(errorCode: Int) {
                    super.onStartFailure(errorCode)
                    isAdvertising = false
                    Log.e("BtHidService", "BLE HID Advertising failed with code: $errorCode")
                }
            }

            bleAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
        } catch (e: Exception) {
            Log.e("BtHidService", "startBleAdvertising error", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun stopBleAdvertising() {
        if (!isAdvertising && advertiseCallback == null) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_ADVERTISE) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    return
                }
            }
            advertiseCallback?.let {
                bleAdvertiser?.stopAdvertising(it)
            }
            isAdvertising = false
            advertiseCallback = null
            Log.d("BtHidService", "BLE HID Advertising stopped")
        } catch (e: Exception) {
            Log.e("BtHidService", "stopBleAdvertising error", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(screenReceiver)
        unregisterReceiver(btStateReceiver)
        unregisterReceiver(pairingReceiver)
        cancelAutoReconnect()
        stopBleAdvertising()
        hidDevice?.unregisterApp()
        stopWakeLock()
        stopPingTimer()
        instance = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("MissingPermission")
    fun isCurrentDeviceTv(): Boolean {
        val bClass = hostDevice?.bluetoothClass?.majorDeviceClass
        return bClass == android.bluetooth.BluetoothClass.Device.Major.AUDIO_VIDEO || bClass == 1024
    }

    @SuppressLint("MissingPermission")
    fun isCurrentDeviceProjector(): Boolean {
        val name = (hostDevice?.name ?: "").lowercase()
        val bClass = hostDevice?.bluetoothClass?.majorDeviceClass
        return bClass == android.bluetooth.BluetoothClass.Device.Major.IMAGING ||
               name.contains("projector") || name.contains("nebula") || name.contains("xgimi") ||
               name.contains("benq") || name.contains("epson") || name.contains("viewsonic") ||
               name.contains("freestyle") || name.contains("dangbei") || name.contains("formovie")
    }
}
