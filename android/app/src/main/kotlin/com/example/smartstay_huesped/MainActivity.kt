package com.example.smartstay_huesped

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Context
import android.nfc.NfcAdapter

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smartstay/nfc_hce"
    private val APDU_EVENT_CHANNEL = "smartstay/nfc_hce_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel so SmartStayHceService can push APDU events to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, APDU_EVENT_CHANNEL)
            .setStreamHandler(ApduEventStreamHandler)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHce" -> {
                    val data = call.argument<String>("data")
                    if (data != null) {
                        val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
                        // commit() is synchronous — guarantees data is on disk before service reads it
                        prefs.edit().apply {
                            putString("hce_data", data)
                            putBoolean("hce_active", true)
                            putString("hce_last_apdu", null)
                            commit()
                        }
                        result.success(true)
                    } else {
                        result.error("INVALID_DATA", "Data is null", null)
                    }
                }
                "stopHce" -> {
                    val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putBoolean("hce_active", false)
                        commit()
                    }
                    result.success(true)
                }
                "isNfcEnabled" -> {
                    val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
                    result.success(nfcAdapter?.isEnabled ?: false)
                }
                "getHceStatus" -> {
                    val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
                    val statusMap = mapOf(
                        "isActive" to prefs.getBoolean("hce_active", false),
                        "hasData" to (prefs.getString("hce_data", null) != null),
                        "dataPreview" to (prefs.getString("hce_data", "")?.take(80) ?: ""),
                        "lastApduReceived" to (prefs.getString("hce_last_apdu", null) ?: ""),
                        "lastApduTimestamp" to prefs.getLong("hce_last_apdu_ts", 0L),
                        "apduCount" to prefs.getInt("hce_apdu_count", 0),
                    )
                    result.success(statusMap)
                }
                else -> result.notImplemented()
            }
        }
    }
}
