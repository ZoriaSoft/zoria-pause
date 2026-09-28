package com.zoriasoft.zoriapause

/**
 * Tek kullanımlık UI bayrakları: bildirim izni kartı bir kez gösterildi,
 * tile rehberi kapatıldı. Key'ler [ALL] allowlist'iyle sınırlıdır —
 * MethodChannel'den gelen key enjeksiyonuna kapalı.
 */
class AppFlags(private val store: KeyValueStore) {

    fun get(key: String): Boolean = key in ALL && store.getString(key) == "1"

    fun set(key: String, value: Boolean) {
        if (key !in ALL) return
        store.put(key, if (value) "1" else "0")
    }

    companion object {
        const val NOTIFICATION_ASKED = "notification_asked"
        const val TILE_HINT_DISMISSED = "tile_hint_dismissed"
        const val PREFS_NAME = "zoria_pause_flags"
        val ALL = setOf(NOTIFICATION_ASKED, TILE_HINT_DISMISSED)
    }
}
