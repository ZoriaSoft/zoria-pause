package com.zoriasoft.zoriapause

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

private class LogFakeStore : KeyValueStore {
    var raw: String? = null
    override fun getString(key: String): String? = raw
    override fun put(key: String, value: String?) {
        raw = value
    }
    override fun remove(key: String) {
        raw = null
    }
}

private fun entry(
    epoch: Long = 1000L,
    action: String = "pause",
    source: String = "tile",
    mode: String? = "off",
    specifier: String? = "dns.adguard.com",
    resumeAt: Long? = 2000L,
): PauseEventLog.Entry =
    PauseEventLog.Entry(epoch, action, source, mode, specifier, resumeAt)

class PauseEventLogTest {

    @Test
    fun `add sonrası read aynı olayı döndürür`() {
        val log = PauseEventLog(LogFakeStore())
        val state = PrivateDnsState(true, true, "off", "dns.adguard.com")

        log.add("pause", "tile", state, resumeAt = 2000L)

        val events = log.read()
        assertEquals(1, events.size)
        assertEquals("pause", events[0].action)
        assertEquals("tile", events[0].source)
        assertEquals("off", events[0].mode)
        assertEquals("dns.adguard.com", events[0].specifier)
        assertEquals(2000L, events[0].resumeAt)
    }

    @Test
    fun `null alanlar boş olarak kodlanır ve geri okunur`() {
        val log = PauseEventLog(LogFakeStore())
        val state = PrivateDnsState(true, true, null, null)

        log.add("resume", "app", state, resumeAt = null)

        val event = log.read().single()
        assertNull(event.mode)
        assertNull(event.specifier)
        assertNull(event.resumeAt)
    }

    @Test
    fun `yeni olaylar sona eklenir`() {
        val log = PauseEventLog(LogFakeStore())
        val state = PrivateDnsState(true, true, "off", null)

        log.add("pause", "tile", state)
        log.add("resume", "auto", PrivateDnsState(true, true, "hostname", "x"))

        val actions = log.read().map { it.action }
        assertEquals(listOf("pause", "resume"), actions)
    }

    @Test
    fun `reschedule aksiyonu yeni resumeAt ile okunur`() {
        val log = PauseEventLog(LogFakeStore())
        val state = PrivateDnsState(true, true, "off", "dns.adguard.com")

        log.add("reschedule", "notification", state, resumeAt = 9000L)

        val event = log.read().single()
        assertEquals("reschedule", event.action)
        assertEquals("notification", event.source)
        assertEquals(9000L, event.resumeAt)
    }

    @Test
    fun `MAX_EVENTS aşılınca en eski olaylar düşer`() {
        val log = PauseEventLog(LogFakeStore())
        val state = PrivateDnsState(true, true, "off", null)

        repeat(PauseEventLog.MAX_EVENTS + 10) {
            log.add("pause", "tile", state)
            assertTrue(log.read().size <= PauseEventLog.MAX_EVENTS)
        }
        assertEquals(PauseEventLog.MAX_EVENTS, log.read().size)
    }

    @Test
    fun `bozuk satırlar sessizce atlanır`() {
        val store = LogFakeStore().apply {
            raw = "kötü-satır\n1000|pause|tile|off|dns.adguard.com|2000\n"
        }
        val events = PauseEventLog(store).read()
        assertEquals(1, events.size)
        assertEquals("pause", events[0].action)
        assertEquals(2000L, events[0].resumeAt)
    }

    @Test
    fun `boş log boş liste döndürür`() {
        assertTrue(PauseEventLog(LogFakeStore()).read().isEmpty())
    }
}
