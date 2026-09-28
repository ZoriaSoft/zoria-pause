import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoriapause/features/pause/domain/private_dns_status.dart';
import 'package:zoriapause/features/setup/domain/shizuku_status.dart';

/// Native çekirdek köprüsü — Kotlin tarafındaki karşılık:
/// `MainActivity.CHANNEL_NAME` ("zoriasoft/zoria_pause").
class PrivateDnsRepository {
  PrivateDnsRepository({MethodChannel? channel})
      : _channel = channel ?? MethodChannel(_channelName);

  static const _channelName = 'zoriasoft/zoria_pause';
  final MethodChannel _channel;

  Future<PrivateDnsStatus> getStatus() => _call('getStatus');

  Future<PrivateDnsStatus> pause({int? durationMinutes}) =>
      _call('pause', {'durationMinutes': durationMinutes});

  Future<PrivateDnsStatus> resume() => _call('resume');

  /// Engelleyici DNS kur (AdGuard tek dokunuş / manuel hostname):
  /// mode=hostname + specifier yazar; bayat pause planını temizler.
  Future<PrivateDnsStatus> setupProvider(String hostname) =>
      _call('setupProvider', {'hostname': hostname});

  /// Seçili duraklatma süresini kalıcı yazar — tile aynı değeri okur.
  Future<PrivateDnsStatus> setDuration(int minutes) =>
      _call('setDuration', {'durationMinutes': minutes});

  /// Duraklatılmışken "şu andan itibaren N dk" olarak yeniden planlar.
  /// Elle kapatılmış DNS'te (plansız pause) plan kurar.
  Future<PrivateDnsStatus> rescheduleResume(int minutes) =>
      _call('rescheduleResume', {'durationMinutes': minutes});

  /// Kalan sürenin üzerine N dk ekler ([+5 dk] uzatma aksiyonu).
  Future<PrivateDnsStatus> extendResume(int minutes) =>
      _call('extendResume', {'durationMinutes': minutes});

  /// Tek kullanımlık UI bayrağı yazar (native allowlist key'leri:
  /// constants.dart flag sabitleri).
  Future<void> setFlag(String key, bool value) =>
      _channel.invokeMethod('setFlag', {'key': key, 'value': value});

  /// Native PauseEventLog — olay geçmişinin TEK KAYNAĞI (tile ve auto-resume
  /// Dart'sız çalışır); Drift tablosu bunun senkronu.
  Future<List<Map<Object?, Object?>>> getEventLog() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getEventLog');
    return (raw ?? const []).map((e) => Map<Object?, Object?>.from(e! as Map)).toList();
  }

  /// API 33+ bildirim izni — bilgi kartının [İZİN VER] yanıtından çağrılır;
  /// izin yoksa alarm yine çalışır ama bildirim gösterilemez (dürüst tasarım).
  Future<bool> ensureNotificationPermission() async {
    final granted = await _channel.invokeMethod<Object?>('ensureNotificationPermission');
    return granted == true;
  }

  /// Shizuku kurulum-yardımcısı durumu (yalnızca Setup ekranı).
  Future<ShizukuStatus> shizukuStatus() async =>
      ShizukuStatus.fromMap(await _channel.invokeMethod<Object?>('shizukuStatus'));

  /// Shizuku ile tek dokunuşlu izin akışını başlatır. Akış asenkron:
  /// tamamlanınca native taraf statusChanged yayınlar, router ana panele döner.
  Future<bool> shizukuGrant() async =>
      await _channel.invokeMethod<Object?>('shizukuGrant') == true;

  /// Shizuku Play Store sayfasını açar (market şeması yoksa web mağaza).
  Future<bool> openShizukuInPlay() async =>
      await _channel.invokeMethod<Object?>('openShizukuInPlay') == true;

  /// Kurulu Shizuku uygulamasını açar (kullanıcı başlatıp geri döner).
  Future<bool> openShizukuApp() async =>
      await _channel.invokeMethod<Object?>('openShizukuApp') == true;

  Future<PrivateDnsStatus> _call(String method, [Object? arguments]) async {
    final raw = await _channel.invokeMethod<Object?>(method, arguments);
    return PrivateDnsStatus.fromMap(raw);
  }

  /// Native ContentObserver olaylarını dinler (MainActivity "statusChanged").
  void listen(void Function() onChanged) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'statusChanged') onChanged();
    });
  }

  void cancelListen() => _channel.setMethodCallHandler(null);
}

final privateDnsRepositoryProvider = Provider<PrivateDnsRepository>((ref) {
  return PrivateDnsRepository();
});
