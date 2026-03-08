package com.windpad.app

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
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

    var onStateChanged: ((String, String?, String?) -> Unit)? = null

    private var reconnectRetries = 0
    private val maxRetries = 5
    private var pingTimer: Timer? = null

    private val pairingReceiver = PairingReceiver()

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_ON || intent?.action == Intent.ACTION_USER_PRESENT) {
                if (hostDevice == null) {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    val mac = prefs.getString("last_device_mac", "")
                    if (!mac.isNullOrEmpty()) {
                        reconnectLastDevice(mac)
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
        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            super.onConnectionStateChanged(device, state)
            if (state == BluetoothProfile.STATE_CONNECTED) {
                hostDevice = device
                reconnectRetries = 0
                onStateChanged?.invoke("onConnected", device?.name, device?.address)
                updateNotification(device?.name ?: "Unknown Device")
                startPingTimer()
                Log.d("BtHidService", "Connected to ${device?.name}")
            } else if (state == BluetoothProfile.STATE_CONNECTING) {
                onStateChanged?.invoke("onConnecting", device?.name, device?.address)
            } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                val isBound = device?.bondState == BluetoothDevice.BOND_BONDED
                if (isBound && reconnectRetries < maxRetries) {
                    reconnectRetries++
                    Log.d("BtHidService", "HID disconnected, retrying silent reconnect... (\$reconnectRetries/\$maxRetries)")
                    Handler(Looper.getMainLooper()).postDelayed({
                        device?.address?.let { reconnectLastDevice(it) }
                    }, 500)
                } else {
                    hostDevice = null
                    reconnectRetries = 0
                    stopPingTimer()
                    onStateChanged?.invoke("onDisconnected", null, null)
                    updateNotification(null)
                    Log.d("BtHidService", "Disconnected")
                }
            }
        }
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
            val sdpSettings = BluetoothHidDeviceAppSdpSettings(
                "Windpad",
                "Bluetooth Trackpad",
                "Windpad",
                BluetoothHidDevice.SUBCLASS1_MOUSE,
                HidReportDescriptor.MOUSE_DESCRIPTOR + HidReportDescriptor.KEYBOARD_DESCRIPTOR + HidReportDescriptor.CONSUMER_DESCRIPTOR
            )
            val qosOut = BluetoothHidDeviceAppQosSettings(
                BluetoothHidDeviceAppQosSettings.SERVICE_BEST_EFFORT,
                800, 9, 0, 11250, BluetoothHidDeviceAppQosSettings.MAX
            )
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
        hidDevice?.unregisterApp()
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

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(screenReceiver)
        unregisterReceiver(pairingReceiver)
        stopWakeLock()
        stopPingTimer()
        instance = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
