package com.windpad.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.windpad/hid"
    private var methodChannel: MethodChannel? = null

    private val disconnectReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.windpad.app.DISCONNECT_HID") {
                BtHidForegroundService.instance?.disconnect()
            }
        }
    }

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                    if (device != null) {
                        try {
                            val name = device.name ?: "Nearby Bluetooth Device"
                            val address = device.address ?: ""
                            val type = getDeviceCategory(device)
                            methodChannel?.invokeMethod("onDeviceDiscovered", mapOf(
                                "name" to name,
                                "address" to address,
                                "type" to type
                            ))
                        } catch (e: SecurityException) {}
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    methodChannel?.invokeMethod("onDiscoveryFinished", null)
                }
            }
        }
    }

    private fun getDeviceCategory(device: BluetoothDevice): String {
        return try {
            val name = (device.name ?: "").lowercase()
            if (name.contains("projector") || name.contains("nebula") || name.contains("xgimi") || name.contains("benq") || name.contains("epson") || name.contains("viewsonic") || name.contains("freestyle") || name.contains("dangbei") || name.contains("formovie")) {
                "projector"
            } else {
                val bClass = device.bluetoothClass?.majorDeviceClass ?: 0
                when (bClass) {
                    BluetoothClass.Device.Major.AUDIO_VIDEO, 1024 -> "tv"
                    BluetoothClass.Device.Major.IMAGING -> "projector"
                    BluetoothClass.Device.Major.COMPUTER -> "computer"
                    BluetoothClass.Device.Major.PHONE -> "phone"
                    BluetoothClass.Device.Major.PERIPHERAL -> "peripheral"
                    else -> {
                        if (name.contains("tv") || name.contains("smart") || name.contains("bravia") || name.contains("fire") || name.contains("chromecast")) "tv"
                        else if (name.contains("pc") || name.contains("desktop") || name.contains("laptop") || name.contains("mac") || name.contains("windows")) "computer"
                        else "other"
                    }
                }
            }
        } catch (e: Exception) {
            "other"
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val startServiceIntent = Intent(this, BtHidForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(startServiceIntent)
        } else {
            startService(startServiceIntent)
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        attachCallbackWithRetry()

        methodChannel?.setMethodCallHandler { call, result ->
            val svc = BtHidForegroundService.instance
            when (call.method) {
                "sendMouse" -> {
                    val b = call.argument<Int>("b")?.toByte() ?: 0
                    val x = call.argument<Int>("x")?.toByte() ?: 0
                    val y = call.argument<Int>("y")?.toByte() ?: 0
                    val s = call.argument<Int>("s")?.toByte() ?: 0
                    svc?.sendMouseReport(b, x, y, s)
                    result.success(null)
                }
                "sendKey" -> {
                    val mod = call.argument<Int>("mod")?.toByte() ?: 0
                    val keys = call.argument<List<Int>>("keys")?.map { it.toByte() }?.toByteArray() ?: byteArrayOf()
                    svc?.sendKeyboardReport(mod, keys)
                    result.success(null)
                }
                "sendMedia" -> {
                    val keys = call.argument<List<Int>>("keys")?.map { it.toByte() }?.toByteArray() ?: byteArrayOf()
                    svc?.sendMediaReport(keys)
                    result.success(null)
                }
                "initHid" -> {
                    svc?.initProfile()
                    result.success(true)
                }
                "startAdvert" -> {
                    val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
                    if (adapter != null) {
                        val discoverableIntent = android.content.Intent(android.bluetooth.BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                        discoverableIntent.putExtra(android.bluetooth.BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
                        startActivity(discoverableIntent)
                        svc?.startBleAdvertising()
                        result.success(true)
                    } else {
                        result.error("BLUETOOTH_NULL", "Adapter is null", null)
                    }
                }
                "startBleAdvert" -> {
                    svc?.startBleAdvertising()
                    result.success(true)
                }
                "stopBleAdvert" -> {
                    svc?.stopBleAdvertising()
                    result.success(true)
                }
                "getBondedDevices" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    val resultList = mutableListOf<Map<String, String>>()
                    if (adapter != null) {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                if (androidx.core.content.ContextCompat.checkSelfPermission(this@MainActivity, android.Manifest.permission.BLUETOOTH_CONNECT) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                    for (device in adapter.bondedDevices) {
                                        resultList.add(mapOf(
                                            "name" to (device.name ?: "Unknown Device"),
                                            "address" to device.address,
                                            "type" to getDeviceCategory(device)
                                        ))
                                    }
                                }
                            } else {
                                for (device in adapter.bondedDevices) {
                                    resultList.add(mapOf(
                                        "name" to (device.name ?: "Unknown Device"),
                                        "address" to device.address,
                                        "type" to getDeviceCategory(device)
                                    ))
                                }
                            }
                        } catch (e: SecurityException) {
                        }
                    }
                    result.success(resultList)
                }
                "startDiscovery" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter != null) {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                if (androidx.core.content.ContextCompat.checkSelfPermission(this@MainActivity, android.Manifest.permission.BLUETOOTH_SCAN) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                    if (adapter.isDiscovering) adapter.cancelDiscovery()
                                    val ok = adapter.startDiscovery()
                                    result.success(ok)
                                } else {
                                    result.success(false)
                                }
                            } else {
                                if (adapter.isDiscovering) adapter.cancelDiscovery()
                                val ok = adapter.startDiscovery()
                                result.success(ok)
                            }
                        } catch (e: SecurityException) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "cancelDiscovery" -> {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    try {
                        if (adapter?.isDiscovering == true) {
                            adapter.cancelDiscovery()
                        }
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.success(false)
                    }
                }
                "connectToDevice" -> {
                    val mac = call.argument<String>("mac")
                    if (mac != null) {
                        svc?.reconnectLastDevice(mac)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "moveToBackground" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                "disconnect" -> {
                    svc?.disconnect()
                    result.success(null)
                }
                "checkAndReconnect" -> {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    val mac = prefs.getString("last_device_mac", "")
                    if (!mac.isNullOrEmpty()) {
                        svc?.checkAndSyncConnection(mac)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "ensureServiceRunning" -> {
                    result.success(null)
                }
                "requestBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } catch(e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "showSystemNotification" -> {
                    val title = call.argument<String>("title") ?: "WindPad"
                    val message = call.argument<String>("message") ?: ""
                    val notifId = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    showSystemNotification(title, message, notifId)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"))
        }

        val discFilter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(discoveryReceiver, discFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(discoveryReceiver, discFilter)
        }
    }

    private fun attachCallbackWithRetry(attempts: Int = 0) {
        val svc = BtHidForegroundService.instance
        if (svc != null) {
            svc.onStateChanged = { method, name, mac ->
                runOnUiThread {
                    if (method == "onConnected" && mac != null) {
                        val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                        prefs.edit().putString("last_device_mac", mac).apply()
                        
                        val isTv = svc.isCurrentDeviceTv()
                        val isProjector = svc.isCurrentDeviceProjector()
                        methodChannel?.invokeMethod(method, mapOf("name" to name, "isTv" to isTv, "isProjector" to isProjector))
                    } else {
                        methodChannel?.invokeMethod(method, name)
                    }
                }
            }
        } else if (attempts < 20) {
            Handler(Looper.getMainLooper()).postDelayed({
                attachCallbackWithRetry(attempts + 1)
            }, 100)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(disconnectReceiver) } catch (e: Exception) {}
        try { unregisterReceiver(discoveryReceiver) } catch (e: Exception) {}
    }

    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent): Boolean {
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP || keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            methodChannel?.invokeMethod("onVolumeKeyDown", mapOf("keyCode" to keyCode))
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: android.view.KeyEvent): Boolean {
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP || keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            methodChannel?.invokeMethod("onVolumeKeyUp", mapOf("keyCode" to keyCode))
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    private fun showSystemNotification(title: String, message: String, notificationId: Int) {
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
            e.printStackTrace()
        }
    }
}
