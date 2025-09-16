import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundLocationManager: BackgroundLocationManager?
  private var permissionChannel: FlutterMethodChannel?
  private var lifecycleChannel: FlutterMethodChannel?
  
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
    
    backgroundLocationManager = BackgroundLocationManager()
    backgroundLocationManager?.configure(with: locationChannel)
    
    locationChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleLocationMethodCall(call, result: result)
    }
    
    // Permission channel
    permissionChannel = FlutterMethodChannel(
      name: "com.trailrun.permissions",
      binaryMessenger: controller.binaryMessenger
    )
    
    permissionChannel?.setMethodCallHandler { [weak self] (call, result) in
      self?.handlePermissionMethodCall(call, result: result)
    }
    
    // App lifecycle channel
    lifecycleChannel = FlutterMethodChannel(
      name: "com.trailrun.app_lifecycle",
      binaryMessenger: controller.binaryMessenger
    )
  }
  
  private func handleLocationMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startBackgroundLocationUpdates":
      if let args = call.arguments as? [String: Any],
         let activityId = args["activityId"] as? String {
        backgroundLocationManager?.startBackgroundLocationUpdates(activityId: activityId)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing activityId", details: nil))
      }
      
    case "stopBackgroundLocationUpdates":
      backgroundLocationManager?.stopBackgroundLocationUpdates()
      result(nil)
      
    case "pauseBackgroundLocationUpdates":
      backgroundLocationManager?.pauseBackgroundLocationUpdates()
      result(nil)
      
    case "resumeBackgroundLocationUpdates":
      backgroundLocationManager?.resumeBackgroundLocationUpdates()
      result(nil)
      
    case "updateSamplingInterval":
      if let args = call.arguments as? [String: Any],
         let interval = args["intervalSeconds"] as? Double {
        backgroundLocationManager?.updateSamplingInterval(interval: interval)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing intervalSeconds", details: nil))
      }
      
    case "getBatteryInfo":
      let batteryInfo = backgroundLocationManager?.getBatteryInfo() ?? [:]
      result(batteryInfo)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handlePermissionMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getIOSVersion":
      result(UIDevice.current.systemVersion)
      
    case "isLowPowerModeEnabled":
      result(ProcessInfo.processInfo.isLowPowerModeEnabled)
      
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
  
  // MARK: - App Lifecycle
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    lifecycleChannel?.invokeMethod("onBackground", arguments: nil)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    lifecycleChannel?.invokeMethod("onForeground", arguments: nil)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    lifecycleChannel?.invokeMethod("onActive", arguments: nil)
  }
  
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    lifecycleChannel?.invokeMethod("onInactive", arguments: nil)
  }
}
