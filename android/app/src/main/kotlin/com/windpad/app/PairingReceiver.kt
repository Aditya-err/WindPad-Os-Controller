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
        if (intent.action == "android.bluetooth.device.action.PAIRING_REQUEST") {
            val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
            val type = intent.getIntExtra(BluetoothDevice.EXTRA_PAIRING_VARIANT, 0)
            
            // 0: PAIRING_VARIANT_PIN, 3: PAIRING_VARIANT_CONSENT
            if (type == 0 || type == 3) {
                try {
                    val method = device?.javaClass?.getMethod("setPairingConfirmation", Boolean::class.javaPrimitiveType)
                    if (method != null) {
                        method.invoke(device, true)
                        abortBroadcast()
                        Log.d("PairingReceiver", "Auto-confirmed pairing request for ${device?.name}")
                    }
                } catch (e: Exception) {
                    try {
                        // Fallback to wrapper type if primitive type fails
                        val method = device?.javaClass?.getMethod("setPairingConfirmation", Boolean::class.java)
                        method?.invoke(device, true)
                        abortBroadcast()
                    } catch (e2: Exception) {
                        Log.e("PairingReceiver", "Could not auto-confirm pairing", e2)
                    }
                }
            }
        }
    }
}
