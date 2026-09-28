package com.zoriasoft.zoriapause

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

private class DurationFakeStore : KeyValueStore {
    val values = mutableMapOf<String, String?>()
    override fun getString(key: String): String? = values[key]
    override fun put(key: String, value: String?) {
        values[key] = value
    }
    override fun remove(key: String) {
        values.remove(key)
    }
}

class SelectedDurationStoreTest {

    @Test
    fun `kayıt yoksa varsayılan 5 dk döner`() {
        val store = SelectedDurationStore(DurationFakeStore())
        assertEquals(5L, store.get())
    }

    @Test
    fun `set yazdığı değeri kalıcı okutur`() {
        val store = SelectedDurationStore(DurationFakeStore())
        store.set(30)
        assertEquals(30L, store.get())
    }

    @Test
    fun `bozuk kayıt varsayıya düşer`() {
        val prefs = DurationFakeStore().apply { values[SelectedDurationStore.KEY] = "abc" }
        assertEquals(5L, SelectedDurationStore(prefs).get())
    }
}

class AppFlagsTest {

    @Test
    fun `flag kapalı doğar ve set ile açılır`() {
        val flags = AppFlags(DurationFakeStore())
        assertFalse(flags.get(AppFlags.NOTIFICATION_ASKED))
        flags.set(AppFlags.NOTIFICATION_ASKED, true)
        assertTrue(flags.get(AppFlags.NOTIFICATION_ASKED))
    }

    @Test
    fun `allowlist dışı key okunamaz ve yazılamaz`() {
        val prefs = DurationFakeStore()
        val flags = AppFlags(prefs)
        flags.set("evil_key", true)
        assertFalse(flags.get("evil_key"))
        assertTrue(prefs.values.isEmpty())
    }
}
