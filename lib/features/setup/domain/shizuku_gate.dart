/// Shizuku "telefon yeter" kurulum yolu kapısı (fleet review F2, 2026-09-21).
///
/// O yol Shizuku'yu wireless debugging üzerinden başlatmayı gerektirir ve
/// o özellik yalnız Android 11+ (API 30+) mevcuttur. Uygulama API 28+
/// desteklediği için (MIN_PRIVATE_DNS_SDK = 28) API 28-29 cihazlarda bu yol
/// imkânsız bir akışa sokuyordu — dead-end. Kapı kapalıysa kurulum ekranı
/// Shizuku kartı yerine PC/adb komutuna yönlendirir.
library;

/// Wireless debugging (Shizuku telefon-içi başlatma) için gereken minimum
/// SDK — Android 11.
const int kMinPhoneOnlySetupSdk = 30;

/// Shizuku telefon-içi kurulum yolu bu cihazda kullanılabilir mi?
bool shizukuPhonePathSupported(int sdkInt) => sdkInt >= kMinPhoneOnlySetupSdk;
