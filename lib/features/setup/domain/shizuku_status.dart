/// Shizuku kurulum-yardımcısı durumu — yalnızca Setup ekranının tek dokunuşlu
/// izin yolu için. Shizuku runtime bağımlılığı DEĞİLDİR: izin bir kez
/// verilince uygulama bağımsız çalışır.
class ShizukuStatus {
  const ShizukuStatus({
    required this.installed,
    required this.running,
    required this.permissionGranted,
  });

  factory ShizukuStatus.fromMap(Object? raw) {
    final map = Map<Object?, Object?>.from(raw! as Map);
    return ShizukuStatus(
      installed: map['installed'] as bool? ?? false,
      running: map['running'] as bool? ?? false,
      permissionGranted: map['permissionGranted'] as bool? ?? false,
    );
  }

  /// Shizuku uygulaması cihazda kurulu mu?
  final bool installed;

  /// Shizuku server çalışıyor mu (kablosuz eşleştirme/root ile başlatılmış)?
  final bool running;

  /// Kullanıcı Shizuku içinde bu uygulamaya izin vermiş mi?
  final bool permissionGranted;
}
