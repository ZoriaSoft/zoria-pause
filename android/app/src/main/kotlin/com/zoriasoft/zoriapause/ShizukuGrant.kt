package com.zoriasoft.zoriapause

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.RemoteException
import rikka.shizuku.Shizuku

/**
 * Shizuku ile tek dokunuşlu WRITE_SECURE_SETTINGS grant akışı (MVP+1).
 *
 * Sözleşme: Shizuku YALNIZCA kurulum anında kullanılır — izin bir kez
 * verilince kalıcıdır ve uygulama bağımsız çalışır (sunucu/VPN yok ilkesi
 * korunur; Shizuku yerel bir binder köprüsüdür, ağ katmanı eklemez).
 *
 * Komut yürütme UserService deseniyle (AIDL) yapılır — Shizuku.newProcess
 * private ve API 14'te kaldırılacak (CI derleme hatasıyla teyit edildi).
 */
object ShizukuGrant {

    const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
    private const val REQUEST_CODE = 7001
    private const val MIN_SHIZUKU_API = 11 // bindUserService eşiği

    /**
     * Bekleyen izin-dialog listener'ı — her İZİN VER dokunuşunda yenisi
     * eklenmeden önce eskisi çıkarılır (birikim düzeltmesi).
     */
    private var pendingPermissionListener: Shizuku.OnRequestPermissionResultListener? = null

    fun isInstalled(context: Context): Boolean = try {
        context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0)
        true
    } catch (_: Exception) {
        false
    }

    /** Shizuku server çalışıyor mu (binder ping). Çalışmıyorsa exception fırlatır. */
    fun isRunning(): Boolean = try {
        Shizuku.pingBinder()
    } catch (_: Exception) {
        false
    }

    /** Kullanıcı, Shizuku içinde BU uygulamaya izin vermiş mi. */
    fun hasShizukuPermission(): Boolean = try {
        isRunning() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Exception) {
        false
    }

    fun statusMap(context: Context): Map<String, Any?> = mapOf(
        "installed" to isInstalled(context),
        "running" to isRunning(),
        "permissionGranted" to hasShizukuPermission(),
    )

    /**
     * Grant akışını başlatır: gerekirse Shizuku izin diyaloğu açılır, izin
     * gelince UserService bağlanır ve pm grant koşar. Başarılı olunca
     * [onGranted] ana thread'den çağrılır; kullanıcı dialogu reddederse
     * sessiz kalır (kurulum ekranı durum satırı yerinde kalır).
     */
    fun startGrantFlow(context: Context, onGranted: () -> Unit) {
        if (isRunning() && try { Shizuku.getVersion() < MIN_SHIZUKU_API } catch (_: Exception) { true }) {
            return
        }
        when {
            hasShizukuPermission() -> runGrantService(context, onGranted)
            else -> {
                // Listener birikimi düzeltmesi (fleet review 2026-09-21): her
                // İZİN VER dokunuşu eskiden yeni bir listener ekliyordu; artık
                // bekleyen listener varsa önce çıkarılır — tek seferde en fazla
                // bir listener kayıtlı kalır.
                pendingPermissionListener?.let { Shizuku.removeRequestPermissionResultListener(it) }
                val listener = object : Shizuku.OnRequestPermissionResultListener {
                    override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
                        if (requestCode != REQUEST_CODE) return
                        Shizuku.removeRequestPermissionResultListener(this)
                        if (pendingPermissionListener === this) pendingPermissionListener = null
                        if (grantResult == PackageManager.PERMISSION_GRANTED) {
                            runGrantService(context, onGranted)
                        }
                    }
                }
                pendingPermissionListener = listener
                Shizuku.addRequestPermissionResultListener(listener)
                Shizuku.requestPermission(REQUEST_CODE)
            }
        }
    }

    private fun runGrantService(context: Context, onGranted: () -> Unit) {
        val args = Shizuku.UserServiceArgs(
            ComponentName(context, PauseGrantService::class.java),
        )
            .processNameSuffix("pause_grant")
            // v2: AIDL arayüzünden packageName parametresi kaldırıldı —
            // Shizuku UserService binder'ını sürüme göre önbelleklediğinden
            // arayüz değişiminde sürüm artırımı zorunlu (eski binder stub'ı
            // çağrılmaya devam etmesin).
            .version(2)
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder) {
                val grantService = IPauseGrantService.Stub.asInterface(service)
                Thread {
                    val exitCode = try {
                        grantService.grantSecureSettings()
                    } catch (_: RemoteException) {
                        -1
                    }
                    try {
                        Shizuku.unbindUserService(args, this, true)
                    } catch (_: Exception) {
                        // server ölmüş olabilir — önemsiz
                    }
                    if (exitCode == 0) {
                        Handler(context.mainLooper).post(onGranted)
                    } else {
                        android.util.Log.w("ZoriaPause", "grant service exit=$exitCode")
                    }
                }.start()
            }

            override fun onServiceDisconnected(name: ComponentName?) = Unit
        }
        try {
            Shizuku.bindUserService(args, connection)
        } catch (e: Exception) {
            // binder ani öldüyse akış sessizce düşer; kullanıcı tekrar dener.
            // Kalıntı teşhis: logcat -s ZoriaPause ile görünür.
            android.util.Log.w("ZoriaPause", "bindUserService failed", e)
        }
    }
}
