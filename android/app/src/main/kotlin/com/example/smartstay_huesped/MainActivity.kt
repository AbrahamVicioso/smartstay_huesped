package com.example.smartstay_huesped

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.nfc.NfcAdapter

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smartstay/nfc_hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHce" -> {
                    val data = call.argument<String>("data")
                    if (data != null) {
                        val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
                        prefs.edit().apply {
                            putString("hce_data", data)
                            putBoolean("hce_active", true)
                            apply()
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
                        apply()
                    }
                    result.success(true)
                }
                "isNfcEnabled" -> {
                    val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
                    result.success(nfcAdapter?.isEnabled ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }
}
