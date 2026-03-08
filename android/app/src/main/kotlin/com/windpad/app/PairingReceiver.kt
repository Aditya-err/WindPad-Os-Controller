package com.windpad.app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PairingReceiver : BroadcastReceiver() {
    @SuppressLint("MissingPermission")
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != BluetoothDevice.ACTION_PAIRING_REQUEST) return
        
        val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE) ?: return
        val type = intent.getIntExtra(BluetoothDevice.EXTRA_PAIRING_VARIANT, -1)
        
        Log.d("PairingReceiver", "Pairing request type: $type for ${device.name}")

        try {
            when (type) {
                0, // PAIRING_VARIANT_PIN
                7  // PAIRING_VARIANT_PIN_16_DIGITS 
                -> {
                    val method = device.javaClass.getMethod("setPin", ByteArray::class.java)
                    method.invoke(device, "0000".toByteArray(Charsets.UTF_8))
                    Log.d("PairingReceiver", "Auto-set PIN to 0000 for ${device.name}")
                }
                1, 2, 3, 4, 5, 6 -> {
                    val method = device.javaClass.getMethod("setPairingConfirmation", Boolean::class.javaPrimitiveType)
                    method.invoke(device, true)
                    Log.d("PairingReceiver", "Auto-confirmed pairing request for ${device.name}")
                }
            }
            abortBroadcast()
        } catch (e: Exception) {
            // fallback reflection
            try {
                device.javaClass
                    .getMethod("setPairingConfirmation", Boolean::class.java)
                    .invoke(device, true)
                try {
                    device.javaClass
                        .getMethod("cancelPairingUserInput")
                        .invoke(device)
                } catch (ignored: Exception) {}
                abortBroadcast()
            } catch (ignored: Exception) {
                Log.e("PairingReceiver", "Could not fully auto-confirm pairing", ignored)
            }
        }
    }
}
