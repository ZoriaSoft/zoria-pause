/// Tek sürüm kaynağı — pubspec.yaml `version` ile aynı tutulur
/// (bump akışı zoria-version-sync skill'iyle Faz 6'da otomatikleşir).
/// Tam sürüm (pubspec ile aynı). Ekranda yalnız `appVersion` (build'siz) gösterilir.
const String kAppVersion = '0.4.0+2013';

/// Kullanıcıya görünen sürüm — `kAppVersion` build numarasız hali.
const String appVersion = '0.4.0';

/// Android applicationId / paket adı — Play'de kalıcı (kullanıcı kararı
/// 2026-09-05). Değiştirilemez; yalnızca okunur kullanılır.
const String appPackage = 'com.zoriasoft.zoriapause';

/// WRITE_SECURE_SETTINGS adb-grant komutu — setup rehberi ile Play listing
/// aynı metni gösterir.
const String adbGrantCommand =
    'adb shell pm grant $appPackage android.permission.WRITE_SECURE_SETTINGS';

/// Tek kullanımlık UI bayrakları — Kotlin `AppFlags.ALL` allowlist'iyle
/// birebir aynı string'ler olmalı.
const String flagNotificationAsked = 'notification_asked';
const String flagTileHintDismissed = 'tile_hint_dismissed';

/// Varsayılan engelleyici DNS (AdGuard DNS — ücretsiz, hesapsız, DoT destekli).
/// "Reklam engellemeyi kur" tek dokunuşı bu adresi ayarlar.
const String defaultAdGuardHostname = 'dns.adguard.com';
