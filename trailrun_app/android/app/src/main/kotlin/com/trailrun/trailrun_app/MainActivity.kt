package com.trailrun.trailrun_app

import android.content.Intent
import android.os.BatteryManager
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.trailrun.location_service"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                
                "getBatteryInfo" -> {
                    val batteryInfo = getBatteryInfo()
                    result.success(batteryInfo)
                }
                
                else -> result.notImplemented()
            }
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
}
