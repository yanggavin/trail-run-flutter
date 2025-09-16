import Foundation
import CoreLocation
import Flutter

@available(iOS 10.0, *)
class BackgroundLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var methodChannel: FlutterMethodChannel?
    private var isBackgroundTracking = false
    private var currentActivityId: String?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    // Adaptive sampling
    private var currentInterval: TimeInterval = 2.0
    private var lastLocationTime: Date?
    private var lastSpeed: CLLocationSpeed = 0.0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    func configure(with methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0
        
        // Enable background location updates
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        // Pause location updates automatically when possible
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public Methods
    
    func startBackgroundLocationUpdates(activityId: String) {
        guard !isBackgroundTracking else { return }
        
        currentActivityId = activityId
        isBackgroundTracking = true
        
        // Request background task
        beginBackgroundTask()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Enable significant location changes as backup
        locationManager.startMonitoringSignificantLocationChanges()
        
        notifyTrackingStateChanged(state: "active")
    }
    
    func stopBackgroundLocationUpdates() {
        guard isBackgroundTracking else { return }
        
        isBackgroundTracking = false
        currentActivityId = nil
        
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        endBackgroundTask()
        
        notifyTrackingStateChanged(state: "stopped")
    }
    
    func pauseBackgroundLocationUpdates() {
        guard isBackgroundTracking else { return }
        
        locationManager.stopUpdatingLocation()
        notifyTrackingStateChanged(state: "paused")
    }
    
    func resumeBackgroundLocationUpdates() {
        guard isBackgroundTracking else { return }
        
        locationManager.startUpdatingLocation()
        notifyTrackingStateChanged(state: "active")
    }
    
    func updateSamplingInterval(interval: TimeInterval) {
        currentInterval = interval
        
        // Adjust location manager settings based on interval
        if interval <= 1.0 {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else if interval <= 3.0 {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask() {
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "LocationTracking") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isBackgroundTracking, let location = locations.last else { return }
        
        // Apply adaptive sampling
        if shouldProcessLocation(location) {
            processLocation(location)
            lastLocationTime = Date()
            lastSpeed = location.speed
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        notifyTrackingStateChanged(state: "error")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            // Can continue background location updates
            break
        case .authorizedWhenInUse:
            // Limited to foreground only
            print("Background location requires 'Always' permission")
        case .denied, .restricted:
            stopBackgroundLocationUpdates()
            notifyTrackingStateChanged(state: "error")
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    // MARK: - Location Processing
    
    private func shouldProcessLocation(_ location: CLLocation) -> Bool {
        // Check accuracy
        guard location.horizontalAccuracy < 50.0 && location.horizontalAccuracy > 0 else {
            return false
        }
        
        // Check time interval
        if let lastTime = lastLocationTime {
            let timeSinceLastLocation = Date().timeIntervalSince(lastTime)
            if timeSinceLastLocation < currentInterval {
                return false
            }
        }
        
        // Check for outliers (impossible speed)
        if location.speed > 50.0 { // 50 m/s = 180 km/h
            return false
        }
        
        return true
    }
    
    private func processLocation(_ location: CLLocation) {
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "elevation": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "speed": location.speed >= 0 ? location.speed : NSNull(),
            "heading": location.course >= 0 ? location.course : NSNull(),
            "timestamp": Int64(location.timestamp.timeIntervalSince1970 * 1000),
            "sequence": 0 // Will be managed by Flutter side
        ]
        
        methodChannel?.invokeMethod("onLocationUpdate", arguments: locationData)
    }
    
    private func notifyTrackingStateChanged(state: String) {
        methodChannel?.invokeMethod("onTrackingStateChanged", arguments: ["state": state])
    }
    
    // MARK: - Battery Optimization
    
    func getBatteryInfo() -> [String: Any] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        return [
            "level": device.batteryLevel,
            "isLowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled
        ]
    }
}