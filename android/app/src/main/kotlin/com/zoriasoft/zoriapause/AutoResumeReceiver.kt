package com.zoriasoft.zoriapause

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Beş kaynaktan gelir: (1) AlarmManager zamanı doldu, (2) bildirime dokunuldu
 * (şimdi geri aç), (3) bildirim [+5 dk] aksiyonu (uzat), (4) hatırlatma alarmı
 * ateşledi, (5) cihaz reboot oldu (kalan süreyi yeniden kur). Zamanı gelen
 * resume yalnızca HÂLÂ duraklatılmışsa çalışır — kullanıcı arada DNS'i elle
 * açtıysa onun kararı korunur.
 */
class AutoResumeReceiver : BroadcastReceiver() {

    enum class BootAction {
        NOTHING,
        CLEANUP,
        SHOW_ONGOING,
        RESCHEDULE,
        RESUME_NOW,
    }

    override fun onReceive(context: Context, intent: Intent) {
        val coordinator = PauseCoordinator.from(context)
        when (intent.action) {
            PauseNotification.ACTION_RESUME_NOW -> coordinator.resumeAuto(source = "notification")
            PauseNotification.ACTION_EXTEND ->
                coordinator.extendResume(PauseNotification.EXTEND_MINUTES, source = "notification")
            ACTION_REMINDER -> coordinator.showReminder()
            Intent.ACTION_BOOT_COMPLETED -> onBoot(context, coordinator)
            ACTION_AUTO_RESUME -> coordinator.resumeAuto(source = "auto")
        }
    }

    private fun onBoot(context: Context, coordinator: PauseCoordinator) {
        val scheduler = coordinator.scheduler
        val resumeAt = scheduler.resumeAt()
        val state = coordinator.manager.readState()
        when (bootAction(state.isPaused, resumeAt, System.currentTimeMillis())) {
            BootAction.NOTHING -> Unit
            BootAction.CLEANUP -> {
                scheduler.cancel()
                PauseNotification.cancel(context)
                PauseNotification.cancelReminder(context)
            }
            BootAction.SHOW_ONGOING -> PauseNotification.show(context, null)
            BootAction.RESCHEDULE -> {
                scheduler.reschedule(resumeAt!!)
                PauseNotification.show(context, resumeAt)
            }
            BootAction.RESUME_NOW -> coordinator.resumeAuto(source = "auto")
        }
    }

    companion object {
        const val ACTION_AUTO_RESUME = "com.zoriasoft.zoriapause.ACTION_AUTO_RESUME"
        const val ACTION_REMINDER = "com.zoriasoft.zoriapause.ACTION_REMINDER"

        fun bootAction(isPaused: Boolean, resumeAt: Long?, now: Long): BootAction = when {
            !isPaused -> if (resumeAt != null) BootAction.CLEANUP else BootAction.NOTHING
            resumeAt == null -> BootAction.SHOW_ONGOING
            resumeAt > now -> BootAction.RESCHEDULE
            else -> BootAction.RESUME_NOW
        }
    }
}
