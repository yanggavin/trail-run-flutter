import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundLocationManager: BackgroundLocationManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    setupLocationMethodChannel()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupLocationMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let methodChannel = FlutterMethodChannel(
      name: "com.trailrun.location_service",
      binaryMessenger: controller.binaryMessenger
    )
    
    backgroundLocationManager = BackgroundLocationManager()
    backgroundLocationManager?.configure(with: methodChannel)
    
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }
  }
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
}
