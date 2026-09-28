package com.zoriasoft.zoriapause

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile — KORUMA AÇIK / OTOMATİK / DURAKLATILDI.
 * Tek dokunuş toggle. Grant yoksa dokunuş uygulamayı açar (kurulum).
 * Uzun basış: QS_TILE_PREFERENCES → MainActivity.
 */
class PauseTileService : TileService() {

    private var dnsObserver: ContentObserver? = null

    private fun manager(): PrivateDnsManager {
        val granted =
            checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
                PackageManager.PERMISSION_GRANTED
        return PrivateDnsManager(
            settings = GlobalSettingsBackend(contentResolver),
            store = PrefsKeyValueStore(getSharedPreferences(PrivateDnsManager.PREFS_NAME, MODE_PRIVATE)),
            granted = granted,
            sdkInt = Build.VERSION.SDK_INT,
        )
    }

    override fun onStartListening() {
        super.onStartListening()
        refreshTile(manager().readState())
        dnsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                refreshTile(manager().readState())
            }
        }
        contentResolver.registerContentObserver(
            Settings.Global.getUriFor(KEY_PRIVATE_DNS_MODE),
            false,
            dnsObserver!!,
        )
        contentResolver.registerContentObserver(
            Settings.Global.getUriFor(KEY_PRIVATE_DNS_SPECIFIER),
            false,
            dnsObserver!!,
        )
    }

    override fun onStopListening() {
        dnsObserver?.let { contentResolver.unregisterContentObserver(it) }
        dnsObserver = null
        super.onStopListening()
    }

    override fun onClick() {
        val coordinator = PauseCoordinator.from(this)
        val state = coordinator.manager.readState()
        if (!state.granted || !state.supported || state.needsProvider) {
            refreshTile(state)
            openApp()
            return
        }
        val next = if (state.isPaused) {
            coordinator.resume(source = "tile")
        } else {
            coordinator.pause(null, source = "tile")
        }
        refreshTile(next)
    }

    private fun openApp() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= 34) {
            val pending = PendingIntent.getActivity(
                this,
                REQUEST_OPEN_APP,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refreshTile(state: PrivateDnsState) {
        val tile = qsTile ?: return
        tile.state = when {
            !state.granted || !state.supported -> Tile.STATE_UNAVAILABLE
            state.isPaused -> Tile.STATE_INACTIVE
            else -> Tile.STATE_ACTIVE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = when (state.tileCaption()) {
                "setup" -> getString(R.string.tile_subtitle_setup)
                "unsupported" -> getString(R.string.tile_subtitle_unsupported)
                "paused" -> getString(R.string.tile_subtitle_paused)
                "on" -> getString(R.string.tile_subtitle_on)
                else -> getString(R.string.tile_subtitle_auto)
            }
        }
        tile.updateTile()
    }

    companion object {
        private const val REQUEST_OPEN_APP = 10
    }
}
