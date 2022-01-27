import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// BackgroundLocation plugin to get background
/// location updates in iOS and Android
class BackgroundLocation {
  // The channels to be used for communication.
  // This channels are also referenced inside both iOS and Android classes
  static const String _pluginId = "almoullim.com";
  static const MethodChannel _channel =
      const MethodChannel('$_pluginId/background_location');
  static const EventChannel _eventChannel =
      const EventChannel('$_pluginId/background_location_stream');

  /// Stop receiving location updates
  static stopLocationService() async {
    return await _channel.invokeMethod("stop_location_service");
  }

  /// Start receiving location updated
  static startLocationService({double distanceFilter = 0.0}) async {
    return await _channel.invokeMethod("start_location_service",
        <String, dynamic>{"distance_filter": distanceFilter});
  }

  static setAndroidNotification(
      {String title, String message, String icon}) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("set_android_notification",
          <String, dynamic>{"title": title, "message": message, "icon": icon});
    } else {
      //return Promise.resolve();
    }
  }

  static setAndroidConfiguration(int interval) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("set_configuration", <String, dynamic>{
        "interval": interval.toString(),
      });
    } else {
      //return Promise.resolve();
    }
  }

  /// Get the current location once.
  Future<Location> getCurrentLocation() async {
    Completer<Location> completer = Completer();

    Location _location = Location();
    await getLocationUpdates((location) {
      _location = _location.copyWith(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        bearing: location.bearing,
        speed: location.speed,
        time: location.time,
      );

      completer.complete(_location);
    });

    return completer.future;
  }

  /// Ask the user for location permissions
  static getPermissions({Function onGranted, Function onDenied}) async {
    await Permission.locationWhenInUse.request();
    if (await Permission.locationWhenInUse.isGranted) {
      if (onGranted != null) {
        onGranted();
      }
    } else if (await Permission.locationWhenInUse.isDenied ||
        await Permission.locationWhenInUse.isPermanentlyDenied ||
        await Permission.locationWhenInUse.isRestricted) {
      if (onDenied != null) {
        onDenied();
      }
    }
  }

  /// Check what the current permissions status is
  static Future<PermissionStatus> checkPermissions() async {
    PermissionStatus permission = await Permission.locationWhenInUse.status;
    return permission;
  }

  /// Register a function to receive location updates as long as the location
  /// service has started
  static getLocationUpdates(Function(Location) location) {
    _eventChannel.receiveBroadcastStream().listen((event) {
      Map locationData = Map.from(event);

      // Call the user passed function
      location(
        Location(
          latitude: locationData["latitude"],
          longitude: locationData["longitude"],
          altitude: locationData["altitude"],
          accuracy: locationData["accuracy"],
          bearing: locationData["bearing"],
          speed: locationData["speed"],
          time: locationData["time"],
          isMock: locationData["is_mock"],
        ),
      );
    });
  }
}

/// An object containing information
/// about the user current location
@immutable
class Location {
  const Location({
    this.longitude,
    this.latitude,
    this.altitude,
    this.accuracy,
    this.bearing,
    this.speed,
    this.time,
    this.isMock,
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final double bearing;
  final double accuracy;
  final double speed;
  final double time;
  final bool isMock;

  Map<String, dynamic> toMap() {
    return {
      'latitude': this.latitude,
      'longitude': this.longitude,
      'altitude': this.altitude,
      'bearing': this.bearing,
      'accuracy': this.accuracy,
      'speed': this.speed,
      'time': this.time,
      'is_mock': this.isMock
    };
  }

  Location copyWith({
    double latitude,
    double longitude,
    double altitude,
    double bearing,
    double accuracy,
    double speed,
    double time,
    bool isMock,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      time: time ?? this.time,
      isMock: isMock ?? this.isMock,
    );
  }
}
