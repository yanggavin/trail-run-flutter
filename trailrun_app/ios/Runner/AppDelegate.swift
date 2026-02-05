import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var locationChannel: FlutterMethodChannel?
  private var isTracking = false
  private var isPaused = false
  private var updateInterval: TimeInterval = 2.0
  private var lastUpdateTime: Date?
  private var sequenceCounter = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    setupMethodChannels()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    // Location service channel
    let locationChannel = FlutterMethodChannel(
      name: "com.trailrun.location_service",
      binaryMessenger: controller.binaryMessenger
    )
    self.locationChannel = locationChannel
    
    locationChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "startBackgroundLocationUpdates":
        self.startBackgroundTracking()
        result(nil)
      case "stopBackgroundLocationUpdates":
        self.stopBackgroundTracking()
        result(nil)
      case "pauseBackgroundLocationUpdates":
        self.pauseBackgroundTracking()
        result(nil)
      case "resumeBackgroundLocationUpdates":
        self.resumeBackgroundTracking()
        result(nil)
      case "updateSamplingInterval":
        if let args = call.arguments as? [String: Any],
           let intervalSeconds = args["intervalSeconds"] as? Int {
          self.updateInterval = TimeInterval(max(1, intervalSeconds))
        }
        result(nil)
      case "getBatteryInfo":
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let batteryLevel = level < 0 ? 1.0 : level
        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        result([
          "level": batteryLevel,
          "isLowPowerMode": isLowPower
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Permission channel
    let permissionChannel = FlutterMethodChannel(
      name: "com.trailrun.permissions",
      binaryMessenger: controller.binaryMessenger
    )
    
    permissionChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getIOSVersion":
        result(UIDevice.current.systemVersion)
      case "isLowPowerModeEnabled":
        result(ProcessInfo.processInfo.isLowPowerModeEnabled)
      case "getBackgroundAppRefreshStatus":
        let status = UIApplication.shared.backgroundRefreshStatus
        switch status {
        case .available:
          result("Available")
        case .denied:
          result("Disabled")
        case .restricted:
          result("Restricted")
        @unknown default:
          result("Unknown")
        }
      case "openAppSettings":
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func ensureLocationManager() {
    if locationManager != nil {
      return
    }
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    if CLLocationManager.authorizationStatus() == .notDetermined {
      manager.requestAlwaysAuthorization()
    }
    locationManager = manager
  }

  private func startBackgroundTracking() {
    ensureLocationManager()
    isTracking = true
    isPaused = false
    locationManager?.startUpdatingLocation()
    locationChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": "active"])
  }

  private func stopBackgroundTracking() {
    isTracking = false
    isPaused = false
    locationManager?.stopUpdatingLocation()
    locationChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": "stopped"])
  }

  private func pauseBackgroundTracking() {
    isPaused = true
    locationChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": "paused"])
  }

  private func resumeBackgroundTracking() {
    isPaused = false
    locationChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": "active"])
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard isTracking, !isPaused, let location = locations.last else { return }

    if let lastUpdate = lastUpdateTime,
       Date().timeIntervalSince(lastUpdate) < updateInterval {
      return
    }
    lastUpdateTime = Date()

    let data: [String: Any] = [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "elevation": location.altitude,
      "accuracy": location.horizontalAccuracy,
      "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000),
      "speed": max(0, location.speed),
      "sequence": sequenceCounter
    ]
    sequenceCounter += 1

    locationChannel?.invokeMethod("onLocationUpdate", arguments: data)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": "error"])
  }
}
