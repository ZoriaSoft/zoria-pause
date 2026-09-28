package com.zoriasoft.zoriapause

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
