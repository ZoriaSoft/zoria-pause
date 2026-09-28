package com.zoriasoft.zoriapause

/**
 * Shizuku server sürecinde (shell/root uid) çalışır; `pm grant` yürütür.
 * İzin bir kez verildikten sonra bu servise bir daha gerek kalmaz.
 */
class PauseGrantService : IPauseGrantService.Stub() {

    override fun grantSecureSettings(): Int = try {
        val process = Runtime.getRuntime()
            .exec(
                arrayOf(
                    "pm",
                    "grant",
                    // Sabit literal: AIDL parametresi kaldırıldı (confused-deputy
                    // sertleştirme). applicationId ile birebir — Play'de kalıcı
                    // (kullanıcı kararı 2026-09-05). Çağıran-verdi paket adına
                    // güvenmek gerekmez; Shizuku çağıranı zaten enforce eder.
                    "com.zoriasoft.zoriapause",
                    "android.permission.WRITE_SECURE_SETTINGS",
                ),
            )
        val exit = process.waitFor()
        if (exit != 0) {
            // Kalıntı teşhis: shell uid sürecinde pm neden başarısızlaştı.
            android.util.Log.w("ZoriaPause", "pm grant exit=$exit")
        }
        exit
    } catch (e: Exception) {
        android.util.Log.w("ZoriaPause", "pm grant exec failed", e)
        -1
    }
}
