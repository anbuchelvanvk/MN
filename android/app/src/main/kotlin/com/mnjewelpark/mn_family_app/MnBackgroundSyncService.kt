package com.mnjewelpark.mn_family_app

import android.app.Service
import android.content.Intent
import android.os.IBinder

class MnBackgroundSyncService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start background polling
        MnNotificationReceiver.scheduleNext(this, 5000)
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Crucial: Fires when user swipes the app away from recent apps list
        MnNotificationReceiver.scheduleNext(this, 1000)
        super.onTaskRemoved(rootIntent)
    }
}
