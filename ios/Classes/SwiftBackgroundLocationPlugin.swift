import Flutter
import UIKit
import CoreLocation

public class SwiftBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, FlutterStreamHandler {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    static var eventChannel: FlutterEventChannel?
    static var eventSink: FlutterEventSink?

    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBackgroundLocationPlugin()
        
        SwiftBackgroundLocationPlugin.channel = FlutterMethodChannel(name: "almoullim.com/background_location", binaryMessenger: registrar.messenger())
        SwiftBackgroundLocationPlugin.eventChannel = FlutterEventChannel(name: "almoullim.com/background_location_stream", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: SwiftBackgroundLocationPlugin.channel!)
        SwiftBackgroundLocationPlugin.channel?.setMethodCallHandler(instance.handle)
        SwiftBackgroundLocationPlugin.eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftBackgroundLocationPlugin.locationManager = CLLocationManager()
        SwiftBackgroundLocationPlugin.locationManager?.delegate = self
        SwiftBackgroundLocationPlugin.locationManager?.requestAlwaysAuthorization()

        SwiftBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates = true
        if #available(iOS 11.0, *) {
            SwiftBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator = true;
        }
        SwiftBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically = false

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "method")

        switch call.method {
            case "start_location_service":
                SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "start_location_service")

                let args = call.arguments as? Dictionary<String, Any>
                let distanceFilter = args?["distance_filter"] as? Double
                SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = distanceFilter ?? 0

                SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
                result(true)


            case "stop_location_service":
                SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "stop_location_service")
                SwiftBackgroundLocationPlugin.locationManager?.stopUpdatingLocation()
                result(true)


            case "get_current_location":
                SwiftBackgroundLocationPlugin.locationManager?.requestLocation() { location in
                    result(location)
                }


            case "open_app_settings":
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { success in
                    result(success)
                })

            case "open_location_settings":
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { success in
                    result(success)
                })
                result(true)


            case "check_permission":
                let status = SwiftBackgroundLocationPlugin.locationManager.authorizationStatus()

                switch status {
                    case .authorizedAlways:
                        result(3)

                    case .authorizedWhenInUse:
                        result(2)

                    case .denied:
                        result(0)

                    case .notDetermined:
                        result(4)

                    case .restricted:
                        result(1)
                }

            case "is_location_service_enabled":
                let isEnabled = SwiftBackgroundLocationPlugin.locationManager.locationServicesEnabled()
                result(isEnabled);

            default:
                result(FlutterMethodNotImplemented)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
           
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = [
            "speed": locations.last!.speed,
            "altitude": locations.last!.altitude,
            "latitude": locations.last!.coordinate.latitude,
            "longitude": locations.last!.coordinate.longitude,
            "accuracy": locations.last!.horizontalAccuracy,
            "bearing": locations.last!.course,
            "time": locations.last!.timestamp.timeIntervalSince1970 * 1000,
            "is_mock": false
        ] as [String : Any]

        SwiftBackgroundLocationPlugin.eventSink?(location)
    }


    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      eventSink = events
      return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      eventSink = null
      return nil
    }
}
