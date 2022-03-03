import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:equatable/equatable.dart';
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

  // Get the current location
  static Future<Location> getCurrentLocation() async {
    try {
      final response = await _channel.invokeMethod(
        "get_current_location",
      );

      Map locationData = Map.from(response);

      return Location(
        latitude: locationData["latitude"],
        longitude: locationData["longitude"],
        altitude: locationData["altitude"],
        accuracy: locationData["accuracy"],
        bearing: locationData["bearing"],
        speed: locationData["speed"],
        time: locationData["time"],
        isMock: locationData["is_mock"],
      );
    } catch (e) {
      return null;
    }
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

  // /// Check what the current permissions status is
  // static Future<PermissionStatus> checkPermissions() async {
  //   PermissionStatus permission = await Permission.locationWhenInUse.status;
  //   return permission;
  // }

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

  /// Calculates the distance between the supplied coordinates in meters.
  ///
  /// The distance between the coordinates is calculated using the Haversine
  /// formula (see https://en.wikipedia.org/wiki/Haversine_formula). The
  /// supplied coordinates [startLatitude], [startLongitude], [endLatitude] and
  /// [endLongitude] should be supplied in degrees.
  static double distanceBetween({
    @required double startLatitude,
    @required double startLongitude,
    @required double endLatitude,
    @required double endLongitude,
  }) {
    var earthRadius = 6378137.0;
    var dLat = _toRadians(endLatitude - startLatitude);
    var dLon = _toRadians(endLongitude - startLongitude);

    var a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) *
            cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude));
    var c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Opens the App settings page.
  ///
  /// Returns [true] if the location settings page could be opened, otherwise
  /// [false] is returned.
  static Future<bool> openAppSettings() async {
    try {
      return await _channel.invokeMethod("open_app_settings");
    } catch (e) {
      return false;
    }
  }

  /// Opens the location settings page.
  ///
  /// Returns [true] if the location settings page could be opened, otherwise
  /// [false] is returned.
  static Future<bool> openLocationSettings() async {
    try {
      return await _channel.invokeMethod("open_location_settings");
    } catch (e) {
      return false;
    }
  }

  /// Returns a [Future] indicating if the user allows the App to access
  /// the device's location.
  static Future<LocationPermission> checkPermission() async {
    try {
      // ignore: omit_local_variable_types
      final int permission = await _channel.invokeMethod('check_permission');

      return permission.toLocationPermission();
    } on PlatformException catch (e) {
      return null;
    }
  }
}

/// An object containing information
/// about the user current location
@immutable
class Location extends Equatable {
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

  @override
  List<Object> get props =>
      [
        latitude,
        longitude,
        altitude,
        bearing,
        accuracy,
        speed,
        time,
        isMock,
      ];
}

/// Represent the possible location permissions.
enum LocationPermission {
  /// This is the initial state on both Android and iOS, but on Android the
  /// user can still choose to deny permissions, meaning the App can still
  /// request for permission another time.
  denied,

  /// Permission to access the device's location is permenantly denied. When
  /// requestiong permissions the permission dialog will not been shown until
  /// the user updates the permission in the App settings.
  deniedForever,

  /// Permission to access the device's location is allowed only while
  /// the App is in use.
  whileInUse,

  /// Permission to access the device's location is allowed even when the
  /// App is running in the background.
  always
}

/// Provides extension methods on the LocationAccuracy enum.
extension IntergerExtensions on int {
  /// Tries to convert the int value to a LocationPermission enum value.
  ///
  /// Throws an InvalidPermissionException if the int value cannot be
  /// converted to a LocationPermission.
  LocationPermission toLocationPermission() {
    switch (this) {
      case 0:
        return LocationPermission.denied;
      case 1:
        return LocationPermission.deniedForever;
      case 2:
        return LocationPermission.whileInUse;
      case 3:
        return LocationPermission.always;
      default:
        throw Exception(
          'Unable to convert the value "$this" into a LocationPermission.',
        );
    }
  }
}
