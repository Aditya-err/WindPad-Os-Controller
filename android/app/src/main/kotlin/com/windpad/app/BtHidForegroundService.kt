package com.windpad.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class BtHidForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    
    companion object {
        const val ACTION_START = "ACTION_START_FOREGROUND_SERVICE"
        const val ACTION_STOP = "ACTION_STOP_FOREGROUND_SERVICE"
        const val ACTION_DISCONNECT = "ACTION_DISCONNECT"
        const val EXTRA_DEVICE_NAME = "EXTRA_DEVICE_NAME"
        const val NOTIFICATION_ID = 101
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val deviceName = intent.getStringExtra(EXTRA_DEVICE_NAME) ?: "Unknown Device"
                startForegroundServiceWithNotification(deviceName)
            }
            ACTION_STOP -> {
                stopWakeLock()
                stopForeground(true)
                stopSelf()
            }
            ACTION_DISCONNECT -> {
                // Send broadcast back to MainActivity to disconnect
                val broadcastIntent = Intent("com.windpad.app.DISCONNECT_HID")
                sendBroadcast(broadcastIntent)
            }
        }
        return START_STICKY
    }

    private fun startForegroundServiceWithNotification(deviceName: String) {
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

        // Intent to open the app
        val openAppIntent = Intent(this, MainActivity::class.java)
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Intent for the disconnect action
        val disconnectIntent = Intent(this, BtHidForegroundService::class.java).apply {
            action = ACTION_DISCONNECT
        }
        val disconnectPendingIntent = PendingIntent.getService(
            this, 1, disconnectIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Windpad is active")
            .setContentText("Connected to $deviceName · Tap to open")
            .setSmallIcon(R.mipmap.ic_launcher) // Fallback app icon
            .setContentIntent(openAppPendingIntent)
            .addAction(0, "Disconnect", disconnectPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        acquireWakeLock()
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "windpad:btkeepawake")
        wakeLock?.acquire()
    }

    private fun stopWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopWakeLock()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
