package com.kurenai7968.volume_controller

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import io.flutter.plugin.common.EventChannel

class VolumeListener(private val context: Context, private val audioManager: AudioManager) : EventChannel.StreamHandler {
    private lateinit var volumeBroadcastReceiver: VolumeBroadcastReceiver

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val args = arguments as? Map<String, Any>
        val fetchInitialVolume = args?.get(EventArgument.FETCH_INITIAL_VOLUME) as? Boolean ?: false

        volumeBroadcastReceiver = VolumeBroadcastReceiver(events, audioManager)
        val filter = IntentFilter().apply {
            addAction(VOLUME_CHANGED_ACTION)
            addAction(AudioManager.ACTION_HEADSET_PLUG)
        }
        context.registerReceiver(volumeBroadcastReceiver, filter)

        if (fetchInitialVolume) {
            events?.success(audioManager.getVolume())
        }
    }

    override fun onCancel(arguments: Any?) {
        context.unregisterReceiver(volumeBroadcastReceiver)
    }
}

class VolumeBroadcastReceiver(private val events: EventChannel.EventSink?, private val audioManager: AudioManager) : BroadcastReceiver() {
    private var lastVolume: Double? = null

    override fun onReceive(context: Context, intent: Intent?) {
        val currentVolume = audioManager.getVolume()
        if (intent?.action == AudioManager.ACTION_HEADSET_PLUG && currentVolume == lastVolume) {
            return
        }
        lastVolume = currentVolume
        events?.success(currentVolume)
    }
}