package com.zoriasoft.zoriapause

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * Pause/resume orkestrasyonu: manager (saf çekirdek) + scheduler (alarm +
 * hatırlatma) + event log (tek kaynak) + seçili süre + UI bayrakları +
 * bildirim. Tüm giriş noktaları (app kanalı, tile, alarm/bildirim/boot
 * receiver) bu sınıfı kullanır.
 */
class PauseCoordinator(
    val manager: PrivateDnsManager,
    val scheduler: PauseScheduler,
    private val log: PauseEventLog,
    val durationStore: SelectedDurationStore,
    val flags: AppFlags,
    private val context: Context,
) {

    fun statusMap(): Map<String, Any?> {
        val state = manager.readState()
        // Elle sistem ayarlarından geri açılmışsa kalıntıları temizle.
        if (!state.isPaused) {
            scheduler.cancel()
            PauseNotification.cancel(context)
            PauseNotification.cancelReminder(context)
        }
        return state.toMap(resumeAt = if (state.isPaused) scheduler.resumeAt() else null) + mapOf(
            "durationMinutes" to durationStore.get(),
            "canNotify" to PauseNotification.canShow(context),
            "notificationPermissionAsked" to flags.get(AppFlags.NOTIFICATION_ASKED),
            "tileHintDismissed" to flags.get(AppFlags.TILE_HINT_DISMISSED),
            // Kurulum ekranının SDK kapısı (fleet review F2, 2026-09-21):
            // Shizuku "telefon yeter" yolu wireless debugging gerektirir ve
            // o yalnız Android 11+ mevcut — API 28-29'da PC/adb yoluna devret.
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }

    /**
     * Duraklat: önceki değeri sakla, mode=off, alarm + bildirim kur.
     * [durationMinutes] null ise kullanıcının kalıcı seçimi (tile davranışı);
     * 0 = SÜRESİZ (alarm ve hatırlatma yok; geri açma elle).
     */
    fun pause(durationMinutes: Long?, source: String): PrivateDnsState {
        val state = manager.pause()
        if (state.isPaused) {
            val minutes = durationMinutes ?: durationStore.get()
            val resumeAt = if (minutes > 0) scheduler.schedule(minutes) else null
            log.add("pause", source, state, resumeAt)
            PauseNotification.show(context, resumeAt)
        }
        return state
    }

    /** Engelleyici DNS kur (AdGuard tek dokunuş / manuel hostname). */
    fun setupProvider(hostname: String, source: String): PrivateDnsState {
        val state = manager.setupProvider(hostname)
        if (state.isProtectionOn) {
            scheduler.cancel()
            PauseNotification.cancel(context)
            PauseNotification.cancelReminder(context)
            log.add("setup", source, state)
        }
        return state
    }

    /** App/bildirim/alarm kaynaklı geri açma. Hâlâ duraklatılmamışsa temizlik. */
    fun resume(source: String): PrivateDnsState {
        val wasPaused = manager.readState().isPaused
        val state = if (wasPaused) manager.resume() else manager.readState()
        scheduler.cancel()
        PauseNotification.cancel(context)
        PauseNotification.cancelReminder(context)
        if (wasPaused) log.add("resume", source, state)
        return state
    }

    fun resumeAuto(source: String) {
        val state = manager.readState()
        if (state.isPaused && state.granted && state.supported) {
            resume(source)
        } else {
            scheduler.cancel()
            PauseNotification.cancel(context)
            PauseNotification.cancelReminder(context)
        }
    }

    /** Panel süre çipleri: şu andan itibaren N dk olarak yeniden planlar.
     *  Süresiz (<= 0): planı ve hatırlatmayı tamamen kaldır, süresiz bildirim. */
    fun rescheduleResume(durationMinutes: Long, source: String): PrivateDnsState {
        val nextAt = nextResumeAt(durationMinutes, System.currentTimeMillis())
        return if (nextAt == null) {
            cancelScheduledResume(source)
        } else {
            applyResumeAt(nextAt, source)
        }
    }

    private fun cancelScheduledResume(source: String): PrivateDnsState {
        val state = manager.readState()
        if (!state.isPaused) return state
        scheduler.cancel()
        log.add("reschedule", source, state, null)
        PauseNotification.show(context, null)
        return manager.readState()
    }

    /** [+5 dk] uzatma: kalan sürenin üzerine ekler; plan yoksa yeni kurar. */
    fun extendResume(durationMinutes: Long, source: String): PrivateDnsState =
        applyResumeAt(
            (scheduler.resumeAt() ?: System.currentTimeMillis()) + durationMinutes * 60_000,
            source,
        )

    /** Hatırlatma alarmı ateşledi — hâlâ duraklatılmışsa bildirimi göster. */
    fun showReminder() {
        val state = manager.readState()
        val resumeAt = scheduler.resumeAt()
        if (!state.isPaused || resumeAt == null || resumeAt <= System.currentTimeMillis()) {
            PauseNotification.cancelReminder(context)
            return
        }
        PauseNotification.showReminder(context, resumeAt)
    }

    private fun applyResumeAt(resumeAt: Long, source: String): PrivateDnsState {
        val state = manager.readState()
        if (!state.granted || !state.supported || !state.isPaused) return state
        PauseNotification.cancelReminder(context)
        scheduler.scheduleAt(resumeAt)
        log.add("reschedule", source, state, resumeAt)
        PauseNotification.show(context, resumeAt)
        return manager.readState()
    }

    fun requestNotificationPermissionIfNeeded(): Boolean {
        if (Build.VERSION.SDK_INT < 33) return true
        val granted = context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) return true
        (context as? MainActivity)?.requestNotificationPermission()
        return false
    }

    companion object {
        /** Yeniden planlama kararı: <= 0 süresiz → plan yok; değilse yeni an. */
        fun nextResumeAt(durationMinutes: Long, now: Long): Long? =
            if (durationMinutes <= 0) null else now + durationMinutes * 60_000

        fun from(context: Context): PauseCoordinator {
            val granted =
                context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
                    PackageManager.PERMISSION_GRANTED
            return PauseCoordinator(
                manager = PrivateDnsManager(
                    settings = GlobalSettingsBackend(context.contentResolver),
                    store = PrefsKeyValueStore(
                        context.getSharedPreferences(PrivateDnsManager.PREFS_NAME, Context.MODE_PRIVATE),
                    ),
                    granted = granted,
                    sdkInt = Build.VERSION.SDK_INT,
                ),
                scheduler = PauseScheduler(context),
                log = PauseEventLog(
                    PrefsKeyValueStore(
                        context.getSharedPreferences(PauseEventLog.PREFS_NAME, Context.MODE_PRIVATE),
                    ),
                ),
                durationStore = SelectedDurationStore(
                    PrefsKeyValueStore(
                        context.getSharedPreferences(PauseScheduler.PREFS_NAME, Context.MODE_PRIVATE),
                    ),
                ),
                flags = AppFlags(
                    PrefsKeyValueStore(
                        context.getSharedPreferences(AppFlags.PREFS_NAME, Context.MODE_PRIVATE),
                    ),
                ),
                context = context,
            )
        }
    }
}

fun PrivateDnsState.toMap(resumeAt: Long? = null): Map<String, Any?> = mapOf(
    "granted" to granted,
    "supported" to supported,
    "mode" to mode,
    "specifier" to specifier,
    "resumeAtEpochMs" to resumeAt,
)

fun PauseEventLog.Entry.toMap(): Map<String, Any?> = mapOf(
    "epochMs" to epochMs,
    "action" to action,
    "source" to source,
    "mode" to mode,
    "specifier" to specifier,
    "resumeAtEpochMs" to resumeAt,
)
