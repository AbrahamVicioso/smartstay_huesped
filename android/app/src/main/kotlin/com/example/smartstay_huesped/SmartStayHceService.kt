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
        Log.d(TAG, "Received APDU: $hexCommand")

        // La cerradura enviará: 00 A4 04 00 07 F0 01 02 03 04 05 06
        // El prefijo + longitud (07) + AID
        val expectedCommand = SELECT_AID_COMMAND_PREFIX + "07" + LOCK_AID
        
        if (hexCommand.uppercase() == expectedCommand.uppercase()) {
            val prefs = getSharedPreferences("SmartStayPrefs", Context.MODE_PRIVATE)
            val jsonData = prefs.getString("hce_data", null)
            val isActive = prefs.getBoolean("hce_active", false)

            Log.d(TAG, "SELECT AID detected. Active: $isActive, HasData: ${jsonData != null}")

            if (isActive && jsonData != null) {
                val responseBytes = jsonData.toByteArray(Charsets.UTF_8)
                val statusBytes = hexStringToByteArray(STATUS_SUCCESS)
                Log.d(TAG, "Sent JSON Response: $jsonData")
                return responseBytes + statusBytes
            } else {
                Log.d(TAG, "HCE ignored: Not active or no data")
            }
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
