package com.zoriasoft.zoriapause

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var dnsObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel!!.setMethodCallHandler { call, result ->
            val coordinator = PauseCoordinator.from(this)
            when (call.method) {
                "isGranted" -> result.success(coordinator.manager.readState().granted)
                "getStatus" -> result.success(coordinator.statusMap())
                "pause" -> {
                    // durationMinutes null olabilir — tile ile aynı kalıcı seçime düşer.
                    val minutes = call.argument<Int>("durationMinutes")?.toLong()
                    coordinator.pause(minutes, source = "app")
                    result.success(coordinator.statusMap())
                }
                "resume" -> {
                    coordinator.resume(source = "app")
                    result.success(coordinator.statusMap())
                }
                "setupProvider" -> {
                    val hostname = call.argument<String>("hostname").orEmpty()
                    coordinator.setupProvider(hostname, source = "app")
                    result.success(coordinator.statusMap())
                }
                "setDuration" -> {
                    val minutes = call.argument<Int>("durationMinutes")?.toLong()
                        ?: SelectedDurationStore.DEFAULT_MINUTES
                    coordinator.durationStore.set(minutes)
                    result.success(coordinator.statusMap())
                }
                "rescheduleResume" -> {
                    val minutes = call.argument<Int>("durationMinutes")?.toLong()
                        ?: SelectedDurationStore.DEFAULT_MINUTES
                    coordinator.rescheduleResume(minutes, source = "app")
                    result.success(coordinator.statusMap())
                }
                "extendResume" -> {
                    val minutes = call.argument<Int>("durationMinutes")?.toLong()
                        ?: SelectedDurationStore.DEFAULT_MINUTES
                    coordinator.extendResume(minutes, source = "app")
                    result.success(coordinator.statusMap())
                }
                "setFlag" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Boolean>("value") ?: false
                    if (key != null) coordinator.flags.set(key, value)
                    result.success(true)
                }
                "getEventLog" -> result.success(
                    PauseEventLog(
                        PrefsKeyValueStore(getSharedPreferences(PauseEventLog.PREFS_NAME, MODE_PRIVATE)),
                    ).read().map { it.toMap() },
                )
                "ensureNotificationPermission" -> {
                    result.success(coordinator.requestNotificationPermissionIfNeeded())
                }
                "shizukuStatus" -> result.success(ShizukuGrant.statusMap(this))
                "shizukuGrant" -> {
                    // Akış asenkron: tamamlanınca (pm grant koştu) statusChanged
                    // yayınlanır → Dart grant'i algılar → router ana panele döner.
                    val started = ShizukuGrant.isRunning() && ShizukuGrant.isInstalled(this)
                    if (started) {
                        ShizukuGrant.startGrantFlow(this) {
                            channel?.invokeMethod("statusChanged", null)
                        }
                    }
                    result.success(started)
                }
                "openShizukuInPlay" -> result.success(openShizukuInPlay())
                "openShizukuApp" -> result.success(openShizukuApp())
                else -> result.notImplemented()
            }
        }
        PauseNotification.ensureChannel(this)
        registerDnsObserver()
    }

    override fun onDestroy() {
        dnsObserver?.let { contentResolver.unregisterContentObserver(it) }
        dnsObserver = null
        super.onDestroy()
    }

    fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < 33) return
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_CODE)
    }

    /** Shizuku Play Store sayfası — market şeması yoksa web mağazaya düş. */
    private fun openShizukuInPlay(): Boolean {
        val market = Uri.parse("market://details?id=${ShizukuGrant.SHIZUKU_PACKAGE}")
        val web = Uri.parse("https://play.google.com/store/apps/details?id=${ShizukuGrant.SHIZUKU_PACKAGE}")
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, market))
            true
        } catch (_: ActivityNotFoundException) {
            try {
                startActivity(Intent(Intent.ACTION_VIEW, web))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    /** Kurulu Shizuku'yu açar (kullanıcı başlatıp geri döner). */
    private fun openShizukuApp(): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(ShizukuGrant.SHIZUKU_PACKAGE)
            ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            channel?.invokeMethod("statusChanged", null)
        }
    }

    /**
     * Tile dışından (sistem ayarları, başka app) private_dns_mode değişirse
     * Dart'a durum-güncelleme olayı yayınlar (ContentObserver).
     */
    private fun registerDnsObserver() {
        dnsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                channel?.invokeMethod("statusChanged", null)
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

    companion object {
        const val CHANNEL_NAME = "zoriasoft/zoria_pause"
        const val NOTIFICATION_PERMISSION_CODE = 42
    }
}
