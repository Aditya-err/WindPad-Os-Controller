package com.windpad.app

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import android.util.Log

class BtHidService(private val context: Context) {
    private var hidDevice: BluetoothHidDevice? = null
    private var hostDevice: BluetoothDevice? = null
    private var onStateChanged: ((String, String?, String?) -> Unit)? = null
    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

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
                onStateChanged?.invoke("onConnected", device?.name, device?.address)
                Log.d("BtHidService", "Connected to ${device?.name}")
            } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
                hostDevice = null
                onStateChanged?.invoke("onDisconnected", null, null)
                Log.d("BtHidService", "Disconnected")
            }
        }
    }

    fun setCallback(callback: (String, String?, String?) -> Unit) {
        onStateChanged = callback
    }

    fun initProfile() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                return
            }
        }
        adapter?.getProfileProxy(context, hidServiceListener, BluetoothProfile.HID_DEVICE)
    }

    @SuppressLint("MissingPermission")
    private fun registerApp() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            if (androidx.core.content.ContextCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_CONNECT) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                return
            }
        }
        try {
            val sdpSettings = BluetoothHidDeviceAppSdpSettings(
                "Windpad",
                "Bluetooth Touchpad & Keyboard",
                "Windpad Inc",
                BluetoothHidDevice.SUBCLASS1_COMBO,
                HidReportDescriptor.MOUSE_DESCRIPTOR + HidReportDescriptor.KEYBOARD_DESCRIPTOR
            )
            val qosOut = BluetoothHidDeviceAppQosSettings(
                BluetoothHidDeviceAppQosSettings.SERVICE_BEST_EFFORT,
                800, 9, 0, 11250, -1
            )
            hidDevice?.registerApp(sdpSettings, null, qosOut, context.mainExecutor, hidCallback)
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
    fun disconnect() {
        hostDevice?.let { device ->
            // Use reflection or hidden APIs if available, but for BluetoothHidDevice
            // dropping the connection usually requires unregistering the app.
            
            adapter?.getProfileProxy(context, object : BluetoothProfile.ServiceListener {
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
        onStateChanged?.invoke("onDisconnected", null, null)
    }

    @SuppressLint("MissingPermission")
    fun reconnectLastDevice(mac: String) {
        if (mac.isEmpty()) return
        val device = adapter?.getRemoteDevice(mac)
        if (device != null && hidDevice != null) {
            val method = hidDevice?.javaClass?.getMethod("connect", BluetoothDevice::class.java)
            if (method != null) {
                method.invoke(hidDevice, device)
            }
        }
    }
}
