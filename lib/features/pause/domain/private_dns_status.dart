/// Private DNS anlık durumu — MethodChannel map'inin tip-safe hâli.
///
/// [mode] değerleri AOSP Private DNS modları: `off` / `opportunistic` /
/// `hostname`; hiç ayarlanmamışsa null (sistem default'u).
class PrivateDnsStatus {
  const PrivateDnsStatus({
    required this.granted,
    required this.supported,
    this.sdkInt = 0,
    this.mode,
    this.specifier,
    this.resumeAtEpochMs,
    this.durationMinutes = 5,
    this.canNotify = true,
    this.notificationPermissionAsked = false,
    this.tileHintDismissed = false,
  });

  factory PrivateDnsStatus.fromMap(Object? raw) {
    final map = Map<Object?, Object?>.from(raw! as Map);
    return PrivateDnsStatus(
      granted: map['granted'] as bool? ?? false,
      supported: map['supported'] as bool? ?? false,
      // Native taraf her zaman gönderir; eksikse 0 = en eski davranış
      // (tüm SDK kapıları kapalı — fail-safe).
      sdkInt: map['sdkInt'] as int? ?? 0,
      mode: map['mode'] as String?,
      specifier: map['specifier'] as String?,
      resumeAtEpochMs: map['resumeAtEpochMs'] as int?,
      durationMinutes: map['durationMinutes'] as int? ?? 5,
      canNotify: map['canNotify'] as bool? ?? true,
      notificationPermissionAsked: map['notificationPermissionAsked'] as bool? ?? false,
      tileHintDismissed: map['tileHintDismissed'] as bool? ?? false,
    );
  }

  /// WRITE_SECURE_SETTINGS verildi mi (adb-grant / Shizuku)?
  final bool granted;

  /// API 28+ (Private DNS özelliği) mevcut mu?
  final bool supported;

  /// Cihazın Android SDK seviyesi (kurulum ekranının SDK kapısı için;
  /// native statusMap'ten gelir).
  final int sdkInt;

  final String? mode;
  final String? specifier;

  /// Duraklatma planlıysa alarm zamanı (epoch ms); değilse null.
  final int? resumeAtEpochMs;

  /// Kalıcı seçili duraklatma süresi (dk) — tile ve app aynı değeri okur.
  final int durationMinutes;

  /// Bildirim gösterilebilir mi (API 33+ izni / altında hep true)?
  final bool canNotify;

  /// Bildirim izni bilgi kartı kullanıcıya hiç gösterildi mi?
  final bool notificationPermissionAsked;

  /// Tile ekleme rehberi kartı kapatıldı mı?
  final bool tileHintDismissed;

  bool get isPaused => mode == 'off';

  /// KORUMA AÇIK = hostname modu (enforce). opportunistic "otomatik"tir;
  /// Faz 5'e kadar tek-satırlık durum metni yalnız bu ikisini ayırt eder.
  bool get isProtectionOn => mode == 'hostname';

  /// Engelleyici yok: hostname modu değil ve specifier boş.
  /// Kurulum adım 2'nin koşulu — opportunistic + boş adres "koruma var" değildir.
  bool get needsProvider => !isProtectionOn && (specifier ?? '').isEmpty;

  /// İlk-açılış bitmedi: izin, engelleyici veya karo adımı eksik.
  /// Desteklenmeyen cihazda kurulum anlamsız.
  bool get onboardingIncomplete =>
      supported && (!granted || needsProvider || !tileHintDismissed);

  /// Bayrak güncellemelerinde loading flash'ı olmadan ekranı tazelemek için.
  PrivateDnsStatus copyWith({
    bool? canNotify,
    bool? notificationPermissionAsked,
    bool? tileHintDismissed,
  }) {
    return PrivateDnsStatus(
      granted: granted,
      supported: supported,
      sdkInt: sdkInt,
      mode: mode,
      specifier: specifier,
      resumeAtEpochMs: resumeAtEpochMs,
      durationMinutes: durationMinutes,
      canNotify: canNotify ?? this.canNotify,
      notificationPermissionAsked: notificationPermissionAsked ?? this.notificationPermissionAsked,
      tileHintDismissed: tileHintDismissed ?? this.tileHintDismissed,
    );
  }
}
