import 'package:flutter_test/flutter_test.dart';

import 'package:zoriapause/features/pause/domain/private_dns_status.dart';
import 'package:zoriapause/features/setup/domain/shizuku_gate.dart';

void main() {
  group('shizukuPhonePathSupported (SDK gate, fleet review F2)', () {
    test('API 28-29 (Android 9-10) telefon-içi yolu reddeder', () {
      expect(shizukuPhonePathSupported(28), isFalse);
      expect(shizukuPhonePathSupported(29), isFalse);
    });

    test('API 30+ (Android 11+) telefon-içi yolu açar', () {
      expect(shizukuPhonePathSupported(30), isTrue);
      expect(shizukuPhonePathSupported(35), isTrue);
    });

    test("eşik sabiti Android 11'e karşılık gelen 30", () {
      expect(kMinPhoneOnlySetupSdk, 30);
      expect(shizukuPhonePathSupported(kMinPhoneOnlySetupSdk), isTrue);
      expect(shizukuPhonePathSupported(kMinPhoneOnlySetupSdk - 1), isFalse);
    });

    test('PrivateDnsStatus sdkInt değerini map taşır', () {
      final status = PrivateDnsStatus.fromMap({
        'granted': false,
        'supported': true,
        'sdkInt': 29,
      });
      expect(status.sdkInt, 29);
      expect(shizukuPhonePathSupported(status.sdkInt), isFalse);
    });

    test("sdkInt eksikse 0'a düşer — kapı fail-safe kapalı", () {
      final status =
          PrivateDnsStatus.fromMap({'granted': false, 'supported': true});
      expect(status.sdkInt, 0);
      expect(shizukuPhonePathSupported(status.sdkInt), isFalse);
    });

    test('copyWith sdkInt korunur', () {
      final status = PrivateDnsStatus.fromMap({'sdkInt': 33});
      expect(status.copyWith(canNotify: false).sdkInt, 33);
    });
  });
}
