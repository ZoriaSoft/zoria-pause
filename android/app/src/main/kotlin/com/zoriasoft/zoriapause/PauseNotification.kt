package com.zoriasoft.zoriapause

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Pause süresince kalıcı (ongoing) sessiz bildirim: geri açma saati + dokun:
 * şimdi geri aç + [+5 dk] uzatma aksiyonu. İkinci, sesli hatırlatma bildirimi
 * (ayrı kanal) resume'dan ~1 dk önce gösterilir — uzatma çağrısına kapıdır.
 */
object PauseNotification {

    const val CHANNEL_ID = "zoria_pause_ongoing"
    const val REMINDER_CHANNEL_ID = "zoria_pause_reminder"
    const val NOTIFICATION_ID = 1
    const val REMINDER_NOTIFICATION_ID = 2
    const val ACTION_RESUME_NOW = "com.zoriasoft.zoriapause.ACTION_RESUME_NOW"
    const val ACTION_EXTEND = "com.zoriasoft.zoriapause.ACTION_EXTEND"
    const val EXTEND_MINUTES = 5L

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notif_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setSound(null, null)
            enableVibration(false)
        }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun ensureReminderChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // IMPORTANCE_DEFAULT: hatırlatma fark edilsin (sesli) — durum
        // bildirimiyle (sessiz LOW) bilinçli ayrışır.
        val channel = NotificationChannel(
            REMINDER_CHANNEL_ID,
            context.getString(R.string.notif_reminder_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun canShow(context: Context): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED

    /**
     * Kalıcı (ongoing) duraklatma bildirimi. [resumeAt] null = SÜRESİZ:
     * saat satırı yerine "elle geri aç" metni, +5 dk uzatma aksiyonu yok
     * (uzatılacak plan bulunmaz).
     */
    fun show(context: Context, resumeAt: Long?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        ensureChannel(context)
        if (!canShow(context)) return
        val bodyText = if (resumeAt != null) {
            val timeText = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(resumeAt))
            context.getString(R.string.notif_paused_text, timeText)
        } else {
            context.getString(R.string.notif_paused_forever_text)
        }
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_pause)
            .setContentTitle(context.getString(R.string.notif_paused_title))
            .setContentText(bodyText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(resumeNowPendingIntent(context))
            .setAutoCancel(false)
        if (resumeAt != null) {
            builder.addAction(extendAction(context))
        }
        context.getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, builder.build())
    }

    /** "Süre dolmak üzere" hatırlatması — tap app'i açar, [+5 dk] uzatır. */
    fun showReminder(context: Context, resumeAt: Long) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        ensureReminderChannel(context)
        if (!canShow(context)) return
        val timeText = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(resumeAt))
        val notification: Notification = Notification.Builder(context, REMINDER_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_pause)
            .setContentTitle(context.getString(R.string.notif_reminder_title))
            .setContentText(context.getString(R.string.notif_reminder_text, timeText))
            .setContentIntent(openAppPendingIntent(context))
            .setAutoCancel(true)
            .addAction(extendAction(context))
            .build()
        context.getSystemService(NotificationManager::class.java)
            .notify(REMINDER_NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
    }

    fun cancelReminder(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(REMINDER_NOTIFICATION_ID)
    }

    private fun extendAction(context: Context): Notification.Action =
        Notification.Action.Builder(
            0,
            context.getString(R.string.notif_extend),
            extendPendingIntent(context),
        ).build()

    private fun resumeNowPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, AutoResumeReceiver::class.java).setAction(ACTION_RESUME_NOW),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun extendPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_EXTEND,
            Intent(context, AutoResumeReceiver::class.java).setAction(ACTION_EXTEND),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun openAppPendingIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private const val REQUEST_CODE_EXTEND = 2
}
