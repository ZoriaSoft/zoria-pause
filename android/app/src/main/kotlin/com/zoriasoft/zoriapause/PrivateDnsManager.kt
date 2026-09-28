package com.zoriasoft.zoriapause

import android.content.ContentResolver
import android.content.SharedPreferences
import android.provider.Settings

// Settings.Global string değerleri (API 28+ Private DNS). Sabitler AOSP'de
// gizli olduğu için literaller kullanılır — adb-grant app'lerin standart pratiği.
const val KEY_PRIVATE_DNS_MODE = "private_dns_mode"
const val KEY_PRIVATE_DNS_SPECIFIER = "private_dns_specifier"
const val MODE_OFF = "off"
const val MODE_OPPORTUNISTIC = "opportunistic"
const val MODE_HOSTNAME = "hostname"

/** Private DNS olası durumları için tek kaynak: cihazdaki anlık Settings değeri. */
data class PrivateDnsState(
    val granted: Boolean,
    val supported: Boolean,
    val mode: String?,
    val specifier: String?,
) {
    val isPaused: Boolean get() = mode == MODE_OFF
    val isProtectionOn: Boolean get() = mode == MODE_HOSTNAME
    val needsProvider: Boolean get() = !isProtectionOn && specifier.isNullOrEmpty()

    /**
     * QS tile altyazı anahtarı. opportunistic "açık" değildir —
     * paneldeki 3 dürüst durumla birebir: setup / unsupported / paused / on / auto.
     */
    fun tileCaption(): String = when {
        !granted -> "setup"
        !supported -> "unsupported"
        isPaused -> "paused"
        isProtectionOn -> "on"
        else -> "auto"
    }
}

/** Settings.Global köprüsü — birim testte bellek-içi fake ile değiştirilir. */
interface SettingsBackend {
    fun getString(key: String): String?
    fun putString(key: String, value: String?)
}

/** Gerçek Settings.Global arka ucu. */
class GlobalSettingsBackend(private val resolver: ContentResolver) : SettingsBackend {
    override fun getString(key: String): String? = Settings.Global.getString(resolver, key)

    /** Yazmanın başarısı çağrıcıyı ilgilendirmez — akış yazma sonrası
     *  readState() ile durumu yeniden okur, başarısız yazma orada görünür. */
    override fun putString(key: String, value: String?) {
        Settings.Global.putString(resolver, key, value)
    }
}

/** Küçük kalıcı KV — pause önceki (mode, specifier) değerini tutar (Faz 4'te Drift). */
interface KeyValueStore {
    fun getString(key: String): String?
    fun put(key: String, value: String?)
    fun remove(key: String)
}

class PrefsKeyValueStore(private val prefs: SharedPreferences) : KeyValueStore {
    override fun getString(key: String): String? = prefs.getString(key, null)
    override fun put(key: String, value: String?) {
        prefs.edit().putString(key, value).apply()
    }
    override fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }
}

/**
 * Pause/resume çekirdeği. Sistem ayarına yalnız [KEY_PRIVATE_DNS_MODE] yazarak
 * duraklatır; specifier'a pause sırasında dokunmaz. Geri açmada önceki değer
 * [KeyValueStore]'dan geri yüklenir; kayıt yoksa mevcut specifier ile hostname
 * moduna döner.
 *
 * Framework'süz tasarım (interface backend + KV + bayraklar) — JUnit ile
 * ContentResolver'sız test edilir.
 */
class PrivateDnsManager(
    private val settings: SettingsBackend,
    private val store: KeyValueStore,
    private val granted: Boolean,
    private val sdkInt: Int,
) {
    val supported: Boolean get() = sdkInt >= MIN_PRIVATE_DNS_SDK

    fun readState(): PrivateDnsState = PrivateDnsState(
        granted = granted,
        supported = supported,
        mode = settings.getString(KEY_PRIVATE_DNS_MODE),
        specifier = settings.getString(KEY_PRIVATE_DNS_SPECIFIER),
    )

    /**
     * Duraklat: önceki değeri sakla, mode=off. Zaten duraklatılmışsa no-op.
     * Önceki mode null ise (sistem default'u) boş string saklanır — restore
     * "default'a dön" demektir.
     */
    fun pause(): PrivateDnsState {
        val current = readState()
        if (!current.granted || !current.supported || current.isPaused) return current
        store.put(PREF_PREVIOUS_MODE, current.mode ?: "")
        store.put(PREF_PREVIOUS_SPECIFIER, current.specifier ?: "")
        settings.putString(KEY_PRIVATE_DNS_MODE, MODE_OFF)
        return readState()
    }

    /** Geri aç: saklanan önceki değeri yükle; kayıt yoksa specifier'dan çıkar. */
    fun resume(): PrivateDnsState {
        val current = readState()
        if (!current.granted || !current.supported) return current
        val storedMode = store.getString(PREF_PREVIOUS_MODE)
        val storedSpecifier = store.getString(PREF_PREVIOUS_SPECIFIER)
        val targetMode = when {
            storedMode == null ->
                // Pause kaydı yok — mevcut specifier ile hostname'e dönülebiliyorsa dön.
                if (!current.specifier.isNullOrEmpty()) MODE_HOSTNAME else return current
            storedMode.isEmpty() -> null
            storedMode == MODE_OFF -> return current
            else -> storedMode
        }
        val targetSpecifier =
            if (targetMode == MODE_HOSTNAME) {
                storedSpecifier?.takeIf { it.isNotEmpty() } ?: current.specifier
            } else {
                null
            }
        if (targetMode == MODE_HOSTNAME && targetSpecifier.isNullOrEmpty()) return current
        // Yazım sırası setupProvider ile hizalı: specifier ÖNCE, mode SONRA.
        // Mode'u ilk yazıp süreç specifier'dan önce ölürse hostname modu bayat
        // specifier'a commit olur (kırık DNS). Specifier'ın önce yazılması
        // mode değişimini atomik commit noktası yapar (fleet review 2026-09-21).
        if (targetMode == MODE_HOSTNAME) {
            settings.putString(KEY_PRIVATE_DNS_SPECIFIER, targetSpecifier)
        }
        settings.putString(KEY_PRIVATE_DNS_MODE, targetMode)
        store.remove(PREF_PREVIOUS_MODE)
        store.remove(PREF_PREVIOUS_SPECIFIER)
        return readState()
    }

    /**
     * Engelleyici DNS kur (AdGuard vb.): mode=hostname + specifier yazar ve
     * bayat pause restore kaydını temizler. Başarısızlık readState ile yüzeye
     * çıkar (yazılamadıysa mode değişmez).
     */
    fun setupProvider(hostname: String): PrivateDnsState {
        if (!granted || !supported) return readState()
        val host = hostname.trim()
        if (host.isEmpty()) return readState()
        settings.putString(KEY_PRIVATE_DNS_SPECIFIER, host)
        settings.putString(KEY_PRIVATE_DNS_MODE, MODE_HOSTNAME)
        store.remove(PREF_PREVIOUS_MODE)
        store.remove(PREF_PREVIOUS_SPECIFIER)
        return readState()
    }

    companion object {
        const val PREFS_NAME = "zoria_pause_state"
        const val PREF_PREVIOUS_MODE = "previous_mode"
        const val PREF_PREVIOUS_SPECIFIER = "previous_specifier"
        const val MIN_PRIVATE_DNS_SDK = 28
    }
}
