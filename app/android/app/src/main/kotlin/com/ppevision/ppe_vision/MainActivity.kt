package com.ppevision.ppe_vision

import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterTextureView

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyWindowRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        applyWindowRefreshRate()
    }

    override fun onFlutterSurfaceViewCreated(flutterSurfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView)
        applyWindowRefreshRate()
        flutterSurfaceView.holder.addCallback(
            object : SurfaceHolder.Callback {
                override fun surfaceCreated(holder: SurfaceHolder) {
                    applyWindowRefreshRate()
                    applySurfaceFrameRate(flutterSurfaceView)
                }

                override fun surfaceChanged(
                    holder: SurfaceHolder,
                    format: Int,
                    width: Int,
                    height: Int,
                ) {
                    applySurfaceFrameRate(flutterSurfaceView)
                }

                override fun surfaceDestroyed(holder: SurfaceHolder) {}
            },
        )
    }

    override fun onFlutterTextureViewCreated(flutterTextureView: FlutterTextureView) {
        super.onFlutterTextureViewCreated(flutterTextureView)
        applyWindowRefreshRate()
    }

    private fun applyWindowRefreshRate() {
        val display = currentDisplay() ?: return
        val peakHz = peakRefreshRate(display)
        val params = window.attributes
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            highestRefreshMode(display)?.let { params.preferredDisplayModeId = it.modeId }
        }
        params.preferredRefreshRate = peakHz
        window.attributes = params
    }

    private fun applySurfaceFrameRate(surfaceView: SurfaceView) {
        val display = currentDisplay() ?: return
        val peakHz = peakRefreshRate(display)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            surfaceView.setRequestedFrameRate(peakHz)
        }

        val surface = surfaceView.holder.surface
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && surface != null && surface.isValid) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                surface.setFrameRate(
                    peakHz,
                    Surface.FRAME_RATE_COMPATIBILITY_DEFAULT,
                    Surface.CHANGE_FRAME_RATE_ALWAYS,
                )
            } else {
                surface.setFrameRate(peakHz, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val surfaceControl = surfaceView.surfaceControl ?: return
            if (!surfaceControl.isValid) return
            val transaction = android.view.SurfaceControl.Transaction()
            transaction.setFrameRate(
                surfaceControl,
                peakHz,
                Surface.FRAME_RATE_COMPATIBILITY_DEFAULT,
            )
            transaction.apply()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                transaction.close()
            }
        }
    }

    private fun currentDisplay(): Display? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        }
    }

    private fun peakRefreshRate(display: Display): Float {
        var maxHz = display.refreshRate
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (mode in display.supportedModes) {
                if (mode.refreshRate > maxHz) {
                    maxHz = mode.refreshRate
                }
            }
        }
        return maxHz
    }

    private fun highestRefreshMode(display: Display): Display.Mode? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        val current = display.mode
        val currentPixels = current.physicalWidth.toLong() * current.physicalHeight
        return display.supportedModes
            .filter { mode ->
                mode.physicalWidth.toLong() * mode.physicalHeight == currentPixels
            }.maxByOrNull { it.refreshRate }
            ?: display.supportedModes.maxByOrNull { it.refreshRate }
    }
}
