package com.almoullim.background_location

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.plugin.common.MethodChannel


class LocationHandlerService {

    companion object {

        fun getCurrentLocation(context: Context, result: MethodChannel.Result) {

            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

            val cancellationTokenSource = CancellationTokenSource()
            fusedLocationClient.getCurrentLocation(
                LocationRequest.PRIORITY_HIGH_ACCURACY,
                cancellationTokenSource.token
            )
                .addOnSuccessListener { location: Location? ->
                    run {
                        try {
                            cancellationTokenSource.cancel()

                            if (location == null) {
                                throw  Exception("the location is empty")
                            }

                            val locationMap = HashMap<String, Any>()

                            locationMap["latitude"] = location.latitude
                            locationMap["longitude"] = location.longitude
                            locationMap["altitude"] = location.altitude
                            locationMap["accuracy"] = location.accuracy.toDouble()
                            locationMap["bearing"] = location.bearing.toDouble()
                            locationMap["speed"] = location.speed.toDouble()
                            locationMap["time"] = location.time.toDouble()
                            locationMap["is_mock"] = location.isFromMockProvider


                            result.success(locationMap)
                        } catch (e: Exception) {
                            result.error("BackgroundLocation-Error", "Android: " + e.message, e)
                        }

                    }
                }.addOnCanceledListener {
                    run {
                        result.error("BackgroundLocation-Error", "Android: On canceled", "")
                    }
                }
        }


        fun openAppSettings(context: Context, result: MethodChannel.Result) {
            try {

                val settingsIntent = Intent()
                settingsIntent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                settingsIntent.addCategory(Intent.CATEGORY_DEFAULT)
                settingsIntent.data = Uri.parse("package:" + context.packageName)
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)

                context.startActivity(settingsIntent)
                result.success(true)

            } catch (e: Exception) {
                result.success(false)
            }
        }


        fun openLocationSettings(context: Context, result: MethodChannel.Result) {
            try {
                val settingsIntent = Intent()
                settingsIntent.action = Settings.ACTION_LOCATION_SOURCE_SETTINGS;
                settingsIntent.addCategory(Intent.CATEGORY_DEFAULT);
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
                settingsIntent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);

                context.startActivity(settingsIntent)
                result.success(true)

            } catch (e: Exception) {
                result.success(false)
            }
        }


        fun checkPermission(context: Context, result: MethodChannel.Result) {
            try {
                val permissions: List<String> = getLocationPermissionsFromManifest(context)

                // If target is before Android M, permission is always granted

                // If target is before Android M, permission is always granted
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    return result.success(3)
                }

                var permissionStatus = PackageManager.PERMISSION_DENIED

                for (permission in permissions) {
                    if (ContextCompat.checkSelfPermission(context, permission)
                        == PackageManager.PERMISSION_GRANTED
                    ) {
                        permissionStatus = PackageManager.PERMISSION_GRANTED
                        break
                    }
                }

                if (permissionStatus == PackageManager.PERMISSION_DENIED) {
                    return result.success(0)
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    return result.success(3)
                }

                val wantsBackgroundLocation: Boolean = Utils.hasPermissionInManifest(
                    context, Manifest.permission.ACCESS_BACKGROUND_LOCATION
                )
                if (!wantsBackgroundLocation) {
                    return result.success(2)
                }

                val permissionStatusBackground = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                )
                if (permissionStatusBackground == PackageManager.PERMISSION_GRANTED) {
                    return result.success(3)
                }

                return result.success(2)

            } catch (e: Exception) {
                result.success(false)
            }
        }

        private fun getLocationPermissionsFromManifest(context: Context): List<String> {
            val fineLocationPermissionExists: Boolean = Utils.hasPermissionInManifest(
                context, Manifest.permission.ACCESS_FINE_LOCATION,
            )

            val coarseLocationPermissionExists: Boolean = Utils.hasPermissionInManifest(
                context, Manifest.permission.ACCESS_COARSE_LOCATION
            )

            if (!fineLocationPermissionExists && !coarseLocationPermissionExists) {
                throw Exception("PermissionUndefinedException")
            }

            val permissions: MutableList<String> = ArrayList()
            if (fineLocationPermissionExists) {
                permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
            }

            if (coarseLocationPermissionExists) {
                permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
            }

            return permissions
        }


        fun isLocationServiceEnabled(context: Context, result: MethodChannel.Result) {
            val locationMgr: LocationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

            val isEnabled: Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                locationMgr.isLocationEnabled
            } else {
                locationMgr.isProviderEnabled(LocationManager.GPS_PROVIDER)
            }

            result.success(isEnabled)
        }
    }
}
