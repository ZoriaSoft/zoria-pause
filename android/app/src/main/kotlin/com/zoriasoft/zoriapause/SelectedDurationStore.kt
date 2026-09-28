package com.zoriasoft.zoriapause

/**
 * Seçili duraklatma süresi (dakika) — app ve Quick Settings tile aynı değeri
 * okur, tek kaynak. Kalıcıdır: app yeniden başlasa da seçim düşmez.
 * KeyValueStore tabanlı → saf JVM test edilir.
 */
class SelectedDurationStore(private val store: KeyValueStore) {

    fun get(): Long = store.getString(KEY)?.toLongOrNull() ?: DEFAULT_MINUTES

    fun set(minutes: Long) {
        store.put(KEY, minutes.toString())
    }

    companion object {
        const val KEY = "duration_minutes"
        const val DEFAULT_MINUTES = 5L
    }
}
