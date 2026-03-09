package com.windpad.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
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
                        }
                    }
                    result.success(resultList)
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
                else -> result.notImplemented()
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"), Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(disconnectReceiver, IntentFilter("com.windpad.app.DISCONNECT_HID"))
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
                        methodChannel?.invokeMethod(method, mapOf("name" to name, "isTv" to isTv))
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
        unregisterReceiver(disconnectReceiver)
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
}
