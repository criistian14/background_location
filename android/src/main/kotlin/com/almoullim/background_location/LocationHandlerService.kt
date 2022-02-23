package com.almoullim.background_location

import android.content.Context
import android.location.Location
import android.util.Log
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.CancellationToken
import com.google.android.gms.tasks.CancellationTokenSource
import com.google.android.gms.tasks.OnTokenCanceledListener
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
    }
}
