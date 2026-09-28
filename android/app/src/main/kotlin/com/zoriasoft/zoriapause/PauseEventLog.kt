package com.zoriasoft.zoriapause

/**
 * Olay logu — pause/resume geçmişinin TEK KAYNAĞI. Tile ve auto-resume
 * Dart'sız çalışabildiği için log native tarafta tutulur; Drift (Dart) bunu
 * senkronlayıp sorgular. Format: satır-başına bir olay, pipe-ayrıklı
 * "epochMs|action|source|mode|specifier|resumeAt" (hostname '|' içermez).
 * Framework'süz — saf JVM test edilir.
 */
class PauseEventLog(private val store: KeyValueStore) {

    data class Entry(
        val epochMs: Long,
        val action: String,
        val source: String,
        val mode: String?,
        val specifier: String?,
        val resumeAt: Long?,
    )

    fun add(action: String, source: String, state: PrivateDnsState, resumeAt: Long? = null) {
        val entries = read()
        val line = listOf(
            System.currentTimeMillis().toString(),
            action,
            source,
            state.mode ?: "",
            state.specifier ?: "",
            resumeAt?.toString() ?: "",
        ).joinToString(SEPARATOR)
        store.put(KEY_LOG, (entries.map { it.toLine() } + line).takeLast(MAX_EVENTS).joinToString("\n"))
    }

    fun read(): List<Entry> =
        store.getString(KEY_LOG)
            ?.split("\n")
            ?.filter { it.isNotBlank() }
            ?.mapNotNull { it.toEntry() }
            ?: emptyList()

    private fun Entry.toLine(): String = listOf(
        epochMs.toString(),
        action,
        source,
        mode ?: "",
        specifier ?: "",
        resumeAt?.toString() ?: "",
    ).joinToString(SEPARATOR)

    private fun String.toEntry(): Entry? {
        val parts = split(SEPARATOR)
        if (parts.size != 6) return null
        val epoch = parts[0].toLongOrNull() ?: return null
        val resumeAt = parts[5].takeIf { it.isNotEmpty() }?.toLongOrNull()
        return Entry(
            epochMs = epoch,
            action = parts[1],
            source = parts[2],
            mode = parts[3].takeIf { it.isNotEmpty() },
            specifier = parts[4].takeIf { it.isNotEmpty() },
            resumeAt = resumeAt,
        )
    }

    companion object {
        const val PREFS_NAME = "zoria_pause_log"
        const val KEY_LOG = "event_log"
        const val SEPARATOR = "|"
        const val MAX_EVENTS = 100
    }
}
