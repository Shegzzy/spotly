package com.spotly.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * The channel "new place" pushes arrive on (see AndroidManifest.xml),
     * so they show up as "New places" in the system notification settings.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "new_places",
            "New places",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "When a place opens in the city you're following"
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
