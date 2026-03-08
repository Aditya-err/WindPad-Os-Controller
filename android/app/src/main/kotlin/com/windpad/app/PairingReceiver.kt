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
            val type = intent.getIntExtra(BluetoothDevice.EXTRA_PAIRING_VARIANT, -1)
            
            Log.d("PairingReceiver", "Pairing request type: $type for ${device?.name}")

            when (type) {
                0 -> { // PAIRING_VARIANT_PIN
                    try {
                        val method = device?.javaClass?.getMethod("setPin", ByteArray::class.java)
                        if (method != null) {
                            method.invoke(device, "0000".toByteArray())
                            abortBroadcast()
                            Log.d("PairingReceiver", "Auto-set PIN to 0000 for ${device?.name}")
                        }
                    } catch (e: Exception) {
                        Log.e("PairingReceiver", "Could not set PIN", e)
                    }
                }
                1, 2, 3, 4, 5, 6 -> { 
                    // PAIRING_VARIANT_PASSKEY, PAIRING_VARIANT_PASSKEY_CONFIRMATION, PAIRING_VARIANT_CONSENT etc.
                    try {
                        val method = device?.javaClass?.getMethod("setPairingConfirmation", Boolean::class.javaPrimitiveType)
                        if (method != null) {
                            method.invoke(device, true)
                            abortBroadcast()
                            Log.d("PairingReceiver", "Auto-confirmed pairing request for ${device?.name}")
                        }
                    } catch (e: Exception) {
                        try {
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
}
