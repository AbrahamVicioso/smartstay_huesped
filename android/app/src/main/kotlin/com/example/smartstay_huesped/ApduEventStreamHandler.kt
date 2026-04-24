package com.example.smartstay_huesped

import io.flutter.plugin.common.EventChannel

object ApduEventStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendApduEvent(hexApdu: String, response: String, timestamp: Long) {
        eventSink?.success(mapOf(
            "apdu" to hexApdu,
            "response" to response,
            "timestamp" to timestamp,
        ))
    }
}
