import 'package:background_location/background_location.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String latitude = "waiting...";
  String longitude = "waiting...";
  String altitude = "waiting...";
  String accuracy = "waiting...";
  String bearing = "waiting...";
  String speed = "waiting...";
  String time = "waiting...";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    BackgroundLocation.stopLocationService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Background Location Service'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              locationData("Latitude: " + latitude),
              locationData("Longitude: " + longitude),
              locationData("Altitude: " + altitude),
              locationData("Accuracy: " + accuracy),
              locationData("Bearing: " + bearing),
              locationData("Speed: " + speed),
              locationData("Time: " + time),
              ElevatedButton(
                onPressed: () async {
                  await BackgroundLocation.setAndroidNotification(
                    title: "Background service is running",
                    message: "Background location in progress",
                    icon: "@mipmap/ic_launcher",
                  );
                  //await BackgroundLocation.setAndroidConfiguration(1000);
                  await BackgroundLocation.startLocationService(
                      distanceFilter: 20);
                  BackgroundLocation.getLocationUpdates((location) {
                    setState(() {
                      this.latitude = location.latitude.toString();
                      this.longitude = location.longitude.toString();
                      this.accuracy = location.accuracy.toString();
                      this.altitude = location.altitude.toString();
                      this.bearing = location.bearing.toString();
                      this.speed = location.speed.toString();
                      this.time = DateTime.fromMillisecondsSinceEpoch(
                              location.time.toInt())
                          .toString();
                    });
                    print("""\n
                        Latitude:  $latitude
                        Longitude: $longitude
                        Altitude: $altitude
                        Accuracy: $accuracy
                        Bearing:  $bearing
                        Speed: $speed
                        Time: $time
                      """);
                  });
                },
                child: Text(
                  "Start Location Service",
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  BackgroundLocation.stopLocationService();
                },
                child: Text(
                  "Stop Location Service",
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  getCurrentLocation();
                },
                child: Text(
                  "Get Current Location",
                ),
              ),
              ElevatedButton(
                onPressed: checkPermissions,
                child: Text(
                  "Check Permissions",
                ),
              ),
              ElevatedButton(
                onPressed: openAppSettings,
                child: Text(
                  "Open App Settings",
                ),
              ),
              ElevatedButton(
                onPressed: openLocationSettings,
                child: Text(
                  "Open Location Settings",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget locationData(String data) {
    return Text(
      data,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  void getCurrentLocation() {
    BackgroundLocation.getCurrentLocation().then((location) {
      print("This is current Location " + location.toMap().toString());
    });
  }

  void checkPermissions() {
    BackgroundLocation.checkPermission().then((permission) {
      print("This is Permission Status $permission");
    });
  }

  void openAppSettings() {
    BackgroundLocation.openAppSettings().then((opened) {
      print("Can open App Settings $opened");
    });
  }

  void openLocationSettings() {
    BackgroundLocation.openLocationSettings().then((opened) {
      print("Can open Location Settings $opened");
    });
  }
}
