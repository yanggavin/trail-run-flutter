package com.trailrun.trailrun_app

import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val LOCATION_SERVICE_CHANNEL = "com.trailrun.location_service"
    private val PERMISSION_CHANNEL = "com.trailrun.permissions"
    private val APP_LIFECYCLE_CHANNEL = "com.trailrun.app_lifecycle"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        FlutterEngineCache.getInstance().put("main_engine", flutterEngine)
        
        setupLocationServiceChannel(flutterEngine)
        setupPermissionChannel(flutterEngine)
        setupAppLifecycleChannel(flutterEngine)
    }

    private fun setupLocationServiceChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        val activityId = call.argument<String>("activityId")
                        if (activityId != null) {
                            startLocationTrackingService(activityId)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Missing activityId", null)
                        }
                    }
                    
                    "stopForegroundService" -> {
                        stopLocationTrackingService()
                        result.success(null)
                    }
                    
                    "pauseTracking" -> {
                        pauseLocationTracking()
                        result.success(null)
                    }
                    
                    "resumeTracking" -> {
                        resumeLocationTracking()
                        result.success(null)
                    }
                    
                    "updateSamplingInterval" -> {
                        val interval = call.argument<Int>("intervalSeconds")
                        if (interval != null) {
                            updateSamplingInterval(interval)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Missing intervalSeconds", null)
                        }
                    }
                    
                    "updateServiceNotification" -> {
                        val distance = call.argument<String>("distance") ?: ""
                        val duration = call.argument<String>("duration") ?: ""
                        val pace = call.argument<String>("pace") ?: ""
                        updateServiceNotification(distance, duration, pace)
                        result.success(null)
                    }
                    
                    "getBatteryInfo" -> {
                        val batteryInfo = getBatteryInfo()
                        result.success(batteryInfo)
                    }
                    
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupPermissionChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidSdkVersion" -> {
                        result.success(Build.VERSION.SDK_INT)
                    }
                    "isLowPowerModeEnabled" -> {
                        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(powerManager.isPowerSaveMode)
                    }
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun setupAppLifecycleChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_LIFECYCLE_CHANNEL)
            .setMethodCallHandler { call, result ->
                // Handle app lifecycle events if needed
                result.notImplemented()
            }
    }
    
    private fun startLocationTrackingService(activityId: String) {
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_START_TRACKING
            putExtra("activityId", activityId)
        }
        startForegroundService(intent)
    }
    
    private fun stopLocationTrackingService() {
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_STOP_TRACKING
        }
        startService(intent)
    }
    
    private fun pauseLocationTracking() {
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_PAUSE_TRACKING
        }
        startService(intent)
    }
    
    private fun resumeLocationTracking() {
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_RESUME_TRACKING
        }
        startService(intent)
    }
    
    private fun updateSamplingInterval(intervalSeconds: Int) {
        // This would be communicated to the service via broadcast or shared preferences
        val sharedPrefs = getSharedPreferences("location_tracking", MODE_PRIVATE)
        sharedPrefs.edit().putInt("sampling_interval", intervalSeconds).apply()

        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_UPDATE_INTERVAL
            putExtra("intervalSeconds", intervalSeconds)
        }
        startService(intent)
    }
    
    private fun updateServiceNotification(distance: String, duration: String, pace: String) {
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            action = "UPDATE_NOTIFICATION"
            putExtra("distance", distance)
            putExtra("duration", duration)
            putExtra("pace", pace)
        }
        startService(intent)
    }

    private fun openAppSettings() {
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
    }
    
    private fun getBatteryInfo(): Map<String, Any> {
        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) / 100.0
        val isLowPowerMode = powerManager.isPowerSaveMode
        
        return mapOf(
            "level" to batteryLevel,
            "isLowPowerMode" to isLowPowerMode
        )
    }

    override fun onResume() {
        super.onResume()
        // Notify Flutter that app is in foreground
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, APP_LIFECYCLE_CHANNEL)
                .invokeMethod("onForeground", null)
        }
    }

    override fun onPause() {
        super.onPause()
        // Notify Flutter that app is going to background
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, APP_LIFECYCLE_CHANNEL)
                .invokeMethod("onBackground", null)
        }
    }
}
