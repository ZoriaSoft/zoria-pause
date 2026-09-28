package com.zoriasoft.zoriapause

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * Otomatik geri açma zamanlayıcı. Inexact alarm (setAndAllowWhileIdle) —
 * ±1 dk sapma dürüst olarak app/bildirim metninde belirtilir. schedule EXACT
 * bilinçli kullanılmaz (SCHEDULE_EXACT_ALARM Play politikası yükü yok).
 *
 * İkinci alarm: "süre dolmak üzere" hatırlatması — resume anından
 * [REMINDER_LEAD_MS] önce hatırlatma bildirimi tetikler. Hatırlatma düz set()
 * ile kurulur (Doze'da cihaz uyanıncaya ertelenir, ana alarm kotasına girmez);
 * [cancel] ve reboot reschedule ikisini de kapsar.
 */
class PauseScheduler(private val context: Context) {

    fun schedule(durationMinutes: Long): Long {
        val triggerAt = System.currentTimeMillis() + durationMinutes * 60_000
        scheduleAt(triggerAt)
        return triggerAt
    }

    /** Belirli ana planlar: resume + hatırlatma alarmları ve prefs kaydı. */
    fun scheduleAt(triggerAt: Long) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_RESUME_AT, triggerAt)
            .apply()
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent(context))
        scheduleReminder(triggerAt)
    }

    /** Hatırlatma: resume'dan REMINDER_LEAD_MS önce. Süre zaten yakınsa yeni
     *  kurulmaz ama önceki hatırlatma alarmı her durumda iptal edilir —
     *  yoksa yeniden planlamada eski alarm asılı kalır. */
    fun scheduleReminder(resumeAt: Long) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val reminder = reminderPendingIntent(context)
        alarm.cancel(reminder)
        val triggerAt = resumeAt - REMINDER_LEAD_MS
        if (triggerAt <= System.currentTimeMillis()) return
        alarm.set(AlarmManager.RTC_WAKEUP, triggerAt, reminder)
    }

    fun resumeAt(): Long? =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getLong(KEY_RESUME_AT, -1)
            .takeIf { it > 0 }

    /** Reboot sonrası kalan süreyi yeniden kurmak için (BootReceiver). */
    fun reschedule(triggerAt: Long) {
        scheduleAt(triggerAt)
    }

    fun cancel() {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(pendingIntent(context))
        alarm.cancel(reminderPendingIntent(context))
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_RESUME_AT)
            .apply()
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, AutoResumeReceiver::class.java)
            .setAction(AutoResumeReceiver.ACTION_AUTO_RESUME)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_RESUME,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun reminderPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, AutoResumeReceiver::class.java)
            .setAction(AutoResumeReceiver.ACTION_REMINDER)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_REMINDER,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val PREFS_NAME = "zoria_pause_scheduler"
        const val KEY_RESUME_AT = "resume_at"
        const val REMINDER_LEAD_MS = 60_000L
        const val REQUEST_CODE_RESUME = 0
        const val REQUEST_CODE_REMINDER = 1
    }
}
