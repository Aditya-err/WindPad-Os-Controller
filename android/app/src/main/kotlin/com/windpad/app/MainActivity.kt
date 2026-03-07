package com.windpad.app

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.windpad/hid"
    private var btHidService: BtHidService? = null
    private var methodChannel: MethodChannel? = null

    private val disconnectReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.windpad.app.DISCONNECT_HID") {
                btHidService?.disconnect()
                stopForegroundService()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        btHidService = BtHidService(this)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        btHidService?.setCallback { method, name, mac ->
            runOnUiThread {
                methodChannel?.invokeMethod(method, name)
                if (method == "onConnected" && mac != null) {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("last_device_mac", mac).apply()
                    startForegroundService(name ?: "Unknown Device")
                } else if (method == "onDisconnected") {
                    stopForegroundService()
                }
            }
        }

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendMouse" -> {
                    val b = call.argument<Int>("b")?.toByte() ?: 0
                    val x = call.argument<Int>("x")?.toByte() ?: 0
                    val y = call.argument<Int>("y")?.toByte() ?: 0
                    val s = call.argument<Int>("s")?.toByte() ?: 0
                    btHidService?.sendMouseReport(b, x, y, s)
                    result.success(null)
                }
                "sendKey" -> {
                    val mod = call.argument<Int>("mod")?.toByte() ?: 0
                    val keys = call.argument<List<Int>>("keys")?.map { it.toByte() }?.toByteArray() ?: byteArrayOf()
                    btHidService?.sendKeyboardReport(mod, keys)
                    result.success(null)
                }
                "sendMedia" -> {
                    val keys = call.argument<List<Int>>("keys")?.map { it.toByte() }?.toByteArray() ?: byteArrayOf()
                    btHidService?.sendMediaReport(keys)
                    result.success(null)
                }
                "initHid" -> {
                    btHidService?.initProfile()
                    result.success(true)
                }
                "startAdvert" -> {
                    val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
                    if (adapter != null) {
                        val discoverableIntent = android.content.Intent(android.bluetooth.BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
                        discoverableIntent.putExtra(android.bluetooth.BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
                        startActivity(discoverableIntent)
                        result.success(true)
                    } else {
                        result.error("BLUETOOTH_NULL", "Adapter is null", null)
                    }
                }
                "getBondedDevices" -> {
                    val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
                    val resultList = mutableListOf<Map<String, String>>()
                    if (adapter != null) {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                                if (androidx.core.content.ContextCompat.checkSelfPermission(this@MainActivity, android.Manifest.permission.BLUETOOTH_CONNECT) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                    for (device in adapter.bondedDevices) {
                                        resultList.add(mapOf("name" to (device.name ?: "Unknown"), "address" to device.address))
                                    }
                                }
                            } else {
                                for (device in adapter.bondedDevices) {
                                    resultList.add(mapOf("name" to (device.name ?: "Unknown"), "address" to device.address))
                                }
                            }
                        } catch (e: SecurityException) {
                            // Ignored
                        }
                    }
                    result.success(resultList)
                }
                "connectToDevice" -> {
                    val mac = call.argument<String>("mac")
                    if (mac != null) {
                        btHidService?.reconnectLastDevice(mac)
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
                    btHidService?.disconnect()
                    stopForegroundService()
                    result.success(null)
                }
                "checkAndReconnect" -> {
                    val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
                    val mac = prefs.getString("last_device_mac", "")
                    if (!mac.isNullOrEmpty()) {
                        btHidService?.checkAndSyncConnection(mac)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "ensureServiceRunning" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(disconnectReceiver)
    }

    override fun onResume() {
        super.onResume()
        val prefs = getSharedPreferences("WindpadPrefs", Context.MODE_PRIVATE)
        val mac = prefs.getString("last_device_mac", "")
        if (!mac.isNullOrEmpty()) {
            btHidService?.reconnectLastDevice(mac)
        }
    }

    private fun startForegroundService(deviceName: String) {
        val intent = Intent(this, BtHidForegroundService::class.java).apply {
            action = BtHidForegroundService.ACTION_START
            putExtra(BtHidForegroundService.EXTRA_DEVICE_NAME, deviceName)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopForegroundService() {
        val intent = Intent(this, BtHidForegroundService::class.java).apply {
            action = BtHidForegroundService.ACTION_STOP
        }
        startService(intent) // stopSelf will be called
    }
}
