package com.example.smartstay_huesped

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import android.content.Context

class SmartStayHceService : HostApduService() {

    companion object {
        private const val TAG = "SmartStayHCE"
        private const val SELECT_AID_COMMAND_PREFIX = "00A40400"
        private const val LOCK_AID = "F0010203040506"
        private const val STATUS_SUCCESS = "9000"
        private const val STATUS_FAILED = "6A82"
        private const val MAX_APDU_LEN = 255
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            Log.e(TAG, "APDU null received")
            return hexStringToByteArray(STATUS_FAILED)
        }

        val hexCommand = bytesToHex(commandApdu)
        val ts = System.currentTimeMillis()
        Log.d(TAG, "APDU Received: $hexCommand (${commandApdu.size} bytes)")

        val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
        val count = prefs.getInt("hce_apdu_count", 0) + 1
        prefs.edit().apply {
            putString("hce_last_apdu", hexCommand)
            putLong("hce_last_apdu_ts", ts)
            putInt("hce_apdu_count", count)
            apply()
        }

        val expectedCommand = SELECT_AID_COMMAND_PREFIX + "07" + LOCK_AID

        if (hexCommand.uppercase().startsWith(SELECT_AID_COMMAND_PREFIX)) {
            val jsonData = prefs.getString("hce_data", null)
            val isActive = prefs.getBoolean("hce_active", false)

            Log.d(TAG, "SELECT AID detected. Active: $isActive, HasData: ${jsonData != null}")

            if (isActive && jsonData != null) {
                val responseBytes = jsonData.toByteArray(Charsets.UTF_8)
                Log.d(TAG, "JSON length: ${responseBytes.size} bytes")

                if (responseBytes.size > MAX_APDU_LEN) {
                    Log.w(TAG, "JSON too long for single APDU response: ${responseBytes.size} > $MAX_APDU_LEN")
                }

                val statusBytes = hexStringToByteArray(STATUS_SUCCESS)
                val fullResponse = responseBytes + statusBytes
                val responseHex = bytesToHex(fullResponse)

                Log.d(TAG, "Responding with JSON (${responseBytes.size} bytes + 2 status)")
                Log.d(TAG, "Response preview: ${jsonData.take(100)}...")

                ApduEventStreamHandler.sendApduEvent(hexCommand, responseHex, ts)
                return fullResponse
            } else {
                Log.w(TAG, "HCE inactive or no data — returning FAILED")
                ApduEventStreamHandler.sendApduEvent(hexCommand, STATUS_FAILED, ts)
            }
        } else {
            Log.w(TAG, "Unknown APDU command: $hexCommand")
            Log.d(TAG, "Expected prefix: $SELECT_AID_COMMAND_PREFIX")
            ApduEventStreamHandler.sendApduEvent(hexCommand, STATUS_FAILED, ts)
        }

        return hexStringToByteArray(STATUS_FAILED)
    }

    override fun onDeactivated(reason: Int) {
        val reasonStr = when (reason) {
            0 -> "LINK_LOSS"
            1 -> "DESELECTED"
            2 -> "SESSION_RESET"
            else -> "UNKNOWN($reason)"
        }
        Log.d(TAG, "HCE Deactivated: $reasonStr")
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val hexChars = CharArray(bytes.size * 2)
        for (i in bytes.indices) {
            val v = bytes[i].toInt() and 0xFF
            hexChars[i * 2] = "0123456789ABCDEF"[v ushr 4]
            hexChars[i * 2 + 1] = "0123456789ABCDEF"[v and 0x0F]
        }
        return String(hexChars)
    }

    private fun hexStringToByteArray(s: String): ByteArray {
        val len = s.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}
