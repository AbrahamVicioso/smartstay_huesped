package com.example.smartstay_huesped

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import android.content.Context

class SmartStayHceService : HostApduService() {

    companion object {
        private const val TAG = "SmartStayHCE"
        // SELECT AID command: 00 A4 04 00 + length + AID
        private const val SELECT_AID_COMMAND_PREFIX = "00A40400"
        private const val LOCK_AID = "F0010203040506"
        private const val STATUS_SUCCESS = "9000"
        private const val STATUS_FAILED = "6A82"
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            return hexStringToByteArray(STATUS_FAILED)
        }

        val hexCommand = bytesToHex(commandApdu)
        val ts = System.currentTimeMillis()
        Log.d(TAG, "Received APDU: $hexCommand")

        val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
        val count = prefs.getInt("hce_apdu_count", 0) + 1
        prefs.edit().apply {
            putString("hce_last_apdu", hexCommand)
            putLong("hce_last_apdu_ts", ts)
            putInt("hce_apdu_count", count)
            apply()
        }

        val expectedCommand = SELECT_AID_COMMAND_PREFIX + "07" + LOCK_AID

        if (hexCommand.uppercase() == expectedCommand.uppercase()) {
            val jsonData = prefs.getString("hce_data", null)
            val isActive = prefs.getBoolean("hce_active", false)

            Log.d(TAG, "SELECT AID matched. Active: $isActive, HasData: ${jsonData != null}")

            if (isActive && jsonData != null) {
                val responseBytes = jsonData.toByteArray(Charsets.UTF_8)
                val statusBytes = hexStringToByteArray(STATUS_SUCCESS)
                val responseHex = bytesToHex(responseBytes + statusBytes)
                Log.d(TAG, "Responding with JSON (${responseBytes.size} bytes): $jsonData")
                ApduEventStreamHandler.sendApduEvent(hexCommand, responseHex, ts)
                return responseBytes + statusBytes
            } else {
                Log.d(TAG, "HCE inactive or no data — returning FAILED")
                ApduEventStreamHandler.sendApduEvent(hexCommand, STATUS_FAILED, ts)
            }
        } else {
            Log.d(TAG, "Unknown APDU (expected $expectedCommand)")
            ApduEventStreamHandler.sendApduEvent(hexCommand, STATUS_FAILED, ts)
        }

        return hexStringToByteArray(STATUS_FAILED)
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "Deactivated: $reason")
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
