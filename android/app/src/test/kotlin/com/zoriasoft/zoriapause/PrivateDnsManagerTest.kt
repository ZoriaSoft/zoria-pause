package com.zoriasoft.zoriapause

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Bellek-içi Settings.Global fake'i — ContentResolver yok, saf JVM. */
private class FakeSettings(initial: Map<String, String?> = emptyMap()) : SettingsBackend {
    val writes = mutableListOf<Pair<String, String?>>()

    /** Testler sonuç değerini okur — sınıf zaten dosya-özel, görünür kalır. */
    val values = initial.toMutableMap()

    override fun getString(key: String): String? = values[key]
    override fun putString(key: String, value: String?) {
        writes.add(key to value)
        if (value == null) values.remove(key) else values[key] = value
    }
}

/** Bellek-içi KV fake'i. */
private class FakeStore : KeyValueStore {
    private val values = mutableMapOf<String, String?>()
    override fun getString(key: String): String? = values[key]
    override fun put(key: String, value: String?) {
        if (value == null) values.remove(key) else values[key] = value
    }
    override fun remove(key: String) {
        values.remove(key)
    }
}

private fun manager(
    granted: Boolean = true,
    sdkInt: Int = 30,
    settings: FakeSettings = FakeSettings(),
    store: FakeStore = FakeStore(),
): PrivateDnsManager =
    PrivateDnsManager(settings, store, granted = granted, sdkInt = sdkInt)

class PrivateDnsManagerTest {

    // --- readState ---

    @Test
    fun `readState mode ve specifier değerlerini taşır`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_HOSTNAME, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val state = manager(settings = settings).readState()
        assertTrue(state.granted)
        assertTrue(state.supported)
        assertEquals(MODE_HOSTNAME, state.mode)
        assertEquals("dns.adguard.com", state.specifier)
        assertFalse(state.isPaused)
    }

    @Test
    fun `readState sdk 28 altında desteklenmiyor der`() {
        val state = manager(sdkInt = 27).readState()
        assertFalse(state.supported)
    }

    @Test
    fun `readState mode hiç ayarlanmamışsa null döner`() {
        val state = manager().readState()
        assertNull(state.mode)
    }

    @Test
    fun `tileCaption hostname korumayı on der`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_HOSTNAME, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        assertEquals("on", manager(settings = settings).readState().tileCaption())
    }

    @Test
    fun `tileCaption opportunistic auto der acik demez`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OPPORTUNISTIC))
        assertEquals("auto", manager(settings = settings).readState().tileCaption())
    }

    @Test
    fun `tileCaption off paused der`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        assertEquals("paused", manager(settings = settings).readState().tileCaption())
    }

    @Test
    fun `tileCaption grantsiz setup der`() {
        assertEquals("setup", manager(granted = false).readState().tileCaption())
    }

    // --- pause ---

    @Test
    fun `pause önceki değeri saklar ve mode off yazar specifier'a dokunmaz`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_HOSTNAME, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val store = FakeStore()
        val m = manager(settings = settings, store = store)

        val state = m.pause()

        assertTrue(state.isPaused)
        assertEquals(MODE_OFF, settings.values[KEY_PRIVATE_DNS_MODE])
        assertEquals("dns.adguard.com", settings.values[KEY_PRIVATE_DNS_SPECIFIER])
        assertEquals(MODE_HOSTNAME, store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE))
        assertEquals("dns.adguard.com", store.getString(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER))
    }

    @Test
    fun `pause zaten off ise no-op`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val store = FakeStore()
        val m = manager(settings = settings, store = store)

        m.pause()

        assertTrue(store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE) == null)
        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `pause grant yoksa hiçbir şey yazmaz`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_HOSTNAME))
        val m = manager(granted = false, settings = settings)

        val state = m.pause()

        assertFalse(state.granted)
        assertEquals(MODE_HOSTNAME, settings.values[KEY_PRIVATE_DNS_MODE])
    }

    @Test
    fun `pause sdk 28 altında no-op`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_HOSTNAME))
        val m = manager(sdkInt = 27, settings = settings)

        m.pause()

        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `pause mode null ise boş string saklar`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"))
        val store = FakeStore()
        val m = manager(settings = settings, store = store)

        m.pause()

        assertEquals("", store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE))
    }

    // --- resume ---

    @Test
    fun `resume saklanan hostname değerini geri yükler ve kaydı temizler`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val store = FakeStore().apply {
            put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_HOSTNAME)
            put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "puredns.example.org")
        }
        val m = manager(settings = settings, store = store)

        val state = m.resume()

        assertFalse(state.isPaused)
        assertEquals(MODE_HOSTNAME, settings.values[KEY_PRIVATE_DNS_MODE])
        assertEquals("puredns.example.org", settings.values[KEY_PRIVATE_DNS_SPECIFIER])
        assertNull(store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE))
        assertNull(store.getString(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER))
    }

    @Test
    fun `resume opportunistic önceki değeri specifier yazmadan geri yükler`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val store = FakeStore().apply { put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_OPPORTUNISTIC) }
        val m = manager(settings = settings, store = store)

        m.resume()

        assertEquals(MODE_OPPORTUNISTIC, settings.values[KEY_PRIVATE_DNS_MODE])
        assertNull(settings.writes.firstOrNull { it.first == KEY_PRIVATE_DNS_SPECIFIER })
    }

    @Test
    fun `resume kayıt yoksa mevcut specifier ile hostname'e döner`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "dns.adguard.com"),
        )
        val m = manager(settings = settings, store = FakeStore())

        val state = m.resume()

        assertEquals(MODE_HOSTNAME, state.mode)
        assertEquals("dns.adguard.com", state.specifier)
    }

    @Test
    fun `resume kayıt da specifier da yoksa off kalır`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val m = manager(settings = settings, store = FakeStore())

        val state = m.resume()

        assertTrue(state.isPaused)
        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `resume boş mod kaydı (sistem default) ayarı null yazarak geri yükler`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val store = FakeStore().apply {
            put(PrivateDnsManager.PREF_PREVIOUS_MODE, "")
            put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "")
        }
        val m = manager(settings = settings, store = store)

        val state = m.resume()

        assertNull(settings.values[KEY_PRIVATE_DNS_MODE])
        assertNull(state.mode)
    }

    @Test
    fun `resume hostname specifier'sız kalırsa geri alma iptal olur`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val store = FakeStore().apply {
            put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_HOSTNAME)
            put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "")
        }
        val m = manager(settings = settings, store = store)

        val state = m.resume()

        assertTrue(state.isPaused)
        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `resume grant yoksa hiçbir şey yazmaz`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val store = FakeStore().apply { put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_HOSTNAME) }
        val m = manager(granted = false, settings = settings, store = store)

        m.resume()

        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `resume hostname restore'da specifier mode'dan once yazilir`() {
        val settings = FakeSettings(
            mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF, KEY_PRIVATE_DNS_SPECIFIER to "eski.adguard.com"),
        )
        val store = FakeStore().apply {
            put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_HOSTNAME)
            put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "puredns.example.org")
        }
        val m = manager(settings = settings, store = store)

        m.resume()

        // setupProvider ile hizalı sıra (fleet review 2026-09-21): specifier
        // önce yazılır — yarım kalan yazımda hostname modu bayat specifier'a
        // commit olmaz, mode değişimi atomik commit noktasıdır.
        val specifierIdx = settings.writes.indexOfFirst { it.first == KEY_PRIVATE_DNS_SPECIFIER }
        val modeIdx = settings.writes.indexOfFirst { it.first == KEY_PRIVATE_DNS_MODE }
        assertTrue(specifierIdx >= 0)
        assertTrue(modeIdx >= 0)
        assertTrue("specifier mode'dan once yazilmali", specifierIdx < modeIdx)
        assertEquals("puredns.example.org", settings.values[KEY_PRIVATE_DNS_SPECIFIER])
        assertEquals(MODE_HOSTNAME, settings.values[KEY_PRIVATE_DNS_MODE])
    }

    // --- setupProvider (engelleyici kurma) ---

    @Test
    fun `setupProvider hostname modunu ve specifier'ı yazar`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OPPORTUNISTIC))
        val m = manager(settings = settings)

        val state = m.setupProvider("dns.adguard.com")

        assertTrue(state.isProtectionOn)
        assertEquals("dns.adguard.com", settings.values[KEY_PRIVATE_DNS_SPECIFIER])
        assertEquals(MODE_HOSTNAME, settings.values[KEY_PRIVATE_DNS_MODE])
    }

    @Test
    fun `setupProvider grant yoksa hiçbir şey yazmaz`() {
        val settings = FakeSettings()
        val m = manager(granted = false, settings = settings)

        m.setupProvider("dns.adguard.com")

        assertEquals(0, settings.writes.size)
    }

    @Test
    fun `setupProvider bayat pause kaydını temizler ve boşluğu kırpar`() {
        val settings = FakeSettings(mapOf(KEY_PRIVATE_DNS_MODE to MODE_OFF))
        val store = FakeStore().apply {
            put(PrivateDnsManager.PREF_PREVIOUS_MODE, MODE_OPPORTUNISTIC)
            put(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER, "")
        }
        val m = manager(settings = settings, store = store)

        m.setupProvider(" dns.adguard.com ")

        assertNull(store.getString(PrivateDnsManager.PREF_PREVIOUS_MODE))
        assertNull(store.getString(PrivateDnsManager.PREF_PREVIOUS_SPECIFIER))
        assertEquals("dns.adguard.com", settings.values[KEY_PRIVATE_DNS_SPECIFIER])
    }
}
