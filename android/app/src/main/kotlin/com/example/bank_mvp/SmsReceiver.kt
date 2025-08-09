package com.example.transactly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Telephony

class SmsReceiver(private val onSmsReceived: (Map<String, Any>) -> Unit) : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent?.action) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (sms in messages) {
                val smsData = mapOf(
                    "address" to sms.displayOriginatingAddress,
                    "body" to sms.displayMessageBody,
                    "timestamp" to sms.timestampMillis
                )
                onSmsReceived(smsData)
            }
        }
    }
}
