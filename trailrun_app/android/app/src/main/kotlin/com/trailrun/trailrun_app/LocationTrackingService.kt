package com.trailrun.trailrun_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class LocationTrackingService : Service() {
    companion object {
        const val CHANNEL_ID = "location_tracking_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START_TRACKING = "START_TRACKING"
        const val ACTION_STOP_TRACKING = "STOP_TRACKING"
        const val ACTION_PAUSE_TRACKING = "PAUSE_TRACKING"
        const val ACTION_RESUME_TRACKING = "RESUME_TRACKING"
        
        private const val METHOD_CHANNEL = "com.trailrun.location_service"
    }

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var isTracking = false
    private var isPaused = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        initializeFlutterEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_TRACKING -> startLocationTracking()
            ACTION_STOP_TRACKING -> stopLocationTracking()
            ACTION_PAUSE_TRACKING -> pauseLocationTracking()
            ACTION_RESUME_TRACKING -> resumeLocationTracking()
        }
        
        return START_STICKY // Restart service if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks your location during trail runs"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initializeFlutterEngine() {
        flutterEngine = FlutterEngine(this)
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        methodChannel = MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )
    }

    private fun startLocationTracking() {
        if (isTracking) return
        
        isTracking = true
        isPaused = false
        
        val notification = createTrackingNotification("Tracking your run...")
        startForeground(NOTIFICATION_ID, notification)
        
        // Notify Flutter to start location tracking
        methodChannel?.invokeMethod("startBackgroundTracking", null)
    }

    private fun stopLocationTracking() {
        isTracking = false
        isPaused = false
        
        // Notify Flutter to stop location tracking
        methodChannel?.invokeMethod("stopBackgroundTracking", null)
        
        stopForeground(true)
        stopSelf()
    }

    private fun pauseLocationTracking() {
        if (!isTracking) return
        
        isPaused = true
        val notification = createTrackingNotification("Run paused")
        startForeground(NOTIFICATION_ID, notification)
        
        // Notify Flutter to pause location tracking
        methodChannel?.invokeMethod("pauseBackgroundTracking", null)
    }

    private fun resumeLocationTracking() {
        if (!isTracking) return
        
        isPaused = false
        val notification = createTrackingNotification("Tracking your run...")
        startForeground(NOTIFICATION_ID, notification)
        
        // Notify Flutter to resume location tracking
        methodChannel?.invokeMethod("resumeBackgroundTracking", null)
    }

    private fun createTrackingNotification(contentText: String): Notification {
        val stopIntent = Intent(this, LocationTrackingService::class.java).apply {
            action = ACTION_STOP_TRACKING
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseResumeIntent = Intent(this, LocationTrackingService::class.java).apply {
            action = if (isPaused) ACTION_RESUME_TRACKING else ACTION_PAUSE_TRACKING
        }
        val pauseResumePendingIntent = PendingIntent.getService(
            this, 1, pauseResumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TrailRun")
            .setContentText(contentText)
            .setSmallIcon(R.drawable.launch_background) // You may want to create a proper icon
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                android.R.drawable.ic_media_pause,
                if (isPaused) "Resume" else "Pause",
                pauseResumePendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .build()
    }

    fun updateNotification(distance: String, duration: String, pace: String) {
        val notification = createTrackingNotification(
            "Distance: $distance • Duration: $duration • Pace: $pace"
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
    }
}