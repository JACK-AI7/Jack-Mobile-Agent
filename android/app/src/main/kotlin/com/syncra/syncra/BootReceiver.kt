package com.syncra.syncra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BootReceiver — auto-starts the Jack overlay bubble after phone reboot.
 * Registered in AndroidManifest with BOOT_COMPLETED intent.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON") {

            // Start the overlay service so the bubble is ready immediately
            val svc = Intent(context, JackOverlayService::class.java).apply {
                putExtra(JackOverlayService.EXTRA_MODE, JackOverlayService.MODE_LISTENING)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(svc)
            } else {
                context.startService(svc)
            }
        }
    }
}
