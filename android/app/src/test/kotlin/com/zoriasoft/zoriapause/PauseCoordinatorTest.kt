package com.zoriasoft.zoriapause

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Yeniden planlama kararı: süresiz seçim (0) asla "şimdi" alarmı kurmamalı —
 * canlıda 15 dk'lık pause'un Süresiz'e çevrilmesi anında resume ediyordu
 * (2026-09-06 canlı smoke bulgusu).
 */
class PauseCoordinatorTest {

    @Test
    fun `sifir dakika surez icin plan donmez`() {
        assertNull(PauseCoordinator.nextResumeAt(0, now = 1_000L))
    }

    @Test
    fun `negatif dakika da surez sayilir`() {
        assertNull(PauseCoordinator.nextResumeAt(-5, now = 1_000L))
    }

    @Test
    fun `pozitif dakika simdi uzerine eklenir`() {
        assertEquals(
            1_000L + 15 * 60_000L,
            PauseCoordinator.nextResumeAt(15, now = 1_000L),
        )
    }
}

/** Yazmayı reddeden Settings fake'i: putString false döner, değer değişmez. */
private class RefusingSettings(initial: Map<String, String?>) : SettingsBackend {
    val values = initial.toMutableMap()
    override fun getString(key: String): String? = values[key]
    override fun putString(key: String, value: String?): Boolean = false
}

/** Yazmada exception atan Settings fake'i (izin geri alınmış gibi). */
private class ThrowingSettings(initial: Map<String, String?>) : SettingsBackend {
    val values = initial.toMutableMap()
    override fun getString(key: String): String? = values[key]
    override fun putString(key: String, value: String?): Boolean =
        throw SecurityException("WRITE_SECURE_SETTINGS revoked")
}

/** True dönüp yazmayan Settings fake'i: yalnız geri okuma doğrulaması yakalar. */
private class SilentSettings(initial: Map<String, String?>) : SettingsBackend {
    val values = initial.toMutableMap()
    override fun getString(key: String): String? = values[key]
    override fun putString(key: String, value: String?): Boolean = true
}

private class CoordinatorFakeStore : KeyValueStore {
    private val values = mutableMapOf<String, String?>()
    override fun getString(key: String): String? = values[key]
    override fun put(key: String, value: String?) {
        if (value == null) values.remove(key) else values[key] = value
    }
    override fun remove(key: String) {
        values.remove(key)
    }
}

/**
 * Geri açma doğrulaması: yazma reddi / exception / geri-okuma uyumsuzluğunda
 * kurtarma kaydı korunmalı ve sonuç başarı sayılmamalı — yoksa DNS kapalı
 * kalırken PauseCoordinator alarmı silip 'resume' olayı yazıyordu.
 */
class PauseCoordinatorResumeVerificationTest {

    private fun pausedManager(settings: SettingsBackend, store: CoordinatorFakeStore) =
        PrivateDnsManager(settings, store, granted = true, sdkInt = 30)

    private fun pausedStore(): CoordinatorFakeStore = CoordinatorFakeStore().apply {
        put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_HOSTNAME)
        put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "dns.adguard.com")
    }

    private fun assertRecoveryKept(state: PrivateDnsState, store: CoordinatorFakeStore) {
        assertTrue(state.isPaused)
        assertTrue(state.writeFailed)
        assertFalse(PauseCoordinator.resumeSucceeded(state))
        assertEquals(MODE_HOSTNAME, store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE))
        assertEquals("dns.adguard.com", store.getString(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER))
    }

    @Test
    fun `resume yazma reddedilirse kayit korunur ve basari sayilmaz`() {
        val store = pausedStore()
        val settings = RefusingSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val state = pausedManager(settings, store).resume()
        assertRecoveryKept(state, store)
    }

    @Test
    fun `resume yazma exception atarsa kayit korunur ve basari sayilmaz`() {
        val store = pausedStore()
        val settings = ThrowingSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val state = pausedManager(settings, store).resume()
        assertRecoveryKept(state, store)
    }

    @Test
    fun `resume geri okuma hedefle uyusmazsa kayit korunur ve basari sayilmaz`() {
        val store = pausedStore()
        val settings = SilentSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val state = pausedManager(settings, store).resume()
        assertRecoveryKept(state, store)
    }
}
