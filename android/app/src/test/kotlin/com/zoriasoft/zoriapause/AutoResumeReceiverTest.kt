package com.zoriasoft.zoriapause

import com.zoriasoft.zoriapause.AutoResumeReceiver.BootAction
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Boot tamamlandığında uygulanacak aksiyon kararları.
 * Saf companion fonksiyon [AutoResumeReceiver.bootAction] üzerinden test edilir.
 */
class AutoResumeReceiverTest {

    @Test
    fun `duraklatilmamis ve plansiz reboot NOTHING doner`() {
        assertEquals(
            BootAction.NOTHING,
            AutoResumeReceiver.bootAction(isPaused = false, resumeAt = null, now = 1_000L),
        )
    }

    @Test
    fun `duraklatilmamis ama kalinti plan varsa CLEANUP doner`() {
        assertEquals(
            BootAction.CLEANUP,
            AutoResumeReceiver.bootAction(isPaused = false, resumeAt = 5_000L, now = 1_000L),
        )
    }

    @Test
    fun `suresiz pause ve reboot durumunda SHOW_ONGOING doner regresyon`() {
        assertEquals(
            BootAction.SHOW_ONGOING,
            AutoResumeReceiver.bootAction(isPaused = true, resumeAt = null, now = 1_000L),
        )
    }

    @Test
    fun `duraklatilmis ve sure henuz dolmamis ise RESCHEDULE doner`() {
        assertEquals(
            BootAction.RESCHEDULE,
            AutoResumeReceiver.bootAction(isPaused = true, resumeAt = 2_000L, now = 1_000L),
        )
    }

    @Test
    fun `duraklatilmis ve sure gecmis ise RESUME_NOW doner`() {
        assertEquals(
            BootAction.RESUME_NOW,
            AutoResumeReceiver.bootAction(isPaused = true, resumeAt = 500L, now = 1_000L),
        )
    }
}
