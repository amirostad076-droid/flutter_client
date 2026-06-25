package com.fluxer

import io.flutter.embedding.android.FlutterApplication
import sh.measure.android.Measure
import sh.measure.android.MeasureConfig

class FluxerApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        val apiKey = readMeasureMetaData("sh.measure.android.API_KEY")
        val apiUrl = readMeasureMetaData("sh.measure.android.API_URL")
        if (apiKey.isNullOrBlank() || apiUrl.isNullOrBlank()) {
            return
        }
        Measure.init(
            applicationContext,
            MeasureConfig(
                autoStart = false,
            ),
        )
    }

    private fun readMeasureMetaData(name: String): String? {
        return try {
            val applicationInfo = packageManager.getApplicationInfo(
                packageName,
                android.content.pm.PackageManager.GET_META_DATA,
            )
            applicationInfo.metaData?.getString(name)
        } catch (_: Exception) {
            null
        }
    }
}
