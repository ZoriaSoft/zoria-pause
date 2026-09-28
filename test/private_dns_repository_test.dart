import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zoriapause/features/pause/data/private_dns_repository.dart';
import 'package:zoriapause/features/pause/domain/private_dns_status.dart';

void main() {
  const channel = MethodChannel('zoriasoft/zoria_pause');

  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fromMap eksik alanları güvenle doldurur', () {
    final status = PrivateDnsStatus.fromMap({'granted': false, 'supported': false});
    expect(status.granted, isFalse);
    expect(status.supported, isFalse);
    expect(status.mode, isNull);
    expect(status.specifier, isNull);
    expect(status.isPaused, isFalse);
    expect(status.isProtectionOn, isFalse);
  });

  test('needsProvider ve onboardingIncomplete kurulum kapısını çözer', () {
    final empty = PrivateDnsStatus.fromMap({
      'granted': true,
      'supported': true,
      'mode': 'opportunistic',
      'specifier': null,
      'tileHintDismissed': true,
    });
    expect(empty.needsProvider, isTrue);
    expect(empty.onboardingIncomplete, isTrue);

    final ready = PrivateDnsStatus.fromMap({
      'granted': true,
      'supported': true,
      'mode': 'hostname',
      'specifier': 'dns.adguard.com',
      'tileHintDismissed': true,
    });
    expect(ready.needsProvider, isFalse);
    expect(ready.onboardingIncomplete, isFalse);

    final noTile = PrivateDnsStatus.fromMap({
      'granted': true,
      'supported': true,
      'mode': 'hostname',
      'specifier': 'dns.adguard.com',
      'tileHintDismissed': false,
    });
    expect(noTile.onboardingIncomplete, isTrue);
  });

  test('fromMap hostname durumunu çözer', () {
    final status = PrivateDnsStatus.fromMap({
      'granted': true,
      'supported': true,
      'mode': 'hostname',
      'specifier': 'dns.adguard.com',
    });
    expect(status.isProtectionOn, isTrue);
    expect(status.isPaused, isFalse);
    expect(status.specifier, 'dns.adguard.com');
  });

  test('getStatus native map\u2019i modele çevirir', () async {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getStatus');
      return {'granted': true, 'supported': true, 'mode': 'opportunistic', 'specifier': null};
    });

    final repo = PrivateDnsRepository();
    final status = await repo.getStatus();

    expect(status.granted, isTrue);
    expect(status.mode, 'opportunistic');
    expect(status.specifier, isNull);
  });

  test('pause native çağrısını kanal üzerinden yürütür', () async {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pause');
      return {'granted': true, 'supported': true, 'mode': 'off', 'specifier': 'dns.adguard.com'};
    });

    final status = await PrivateDnsRepository().pause();

    expect(status.isPaused, isTrue);
    expect(status.specifier, 'dns.adguard.com');
  });

  test('fromMap süre ve bayrak alanlarını çözer', () {
    final status = PrivateDnsStatus.fromMap({
      'granted': true,
      'supported': true,
      'mode': 'off',
      'durationMinutes': 15,
      'canNotify': false,
      'notificationPermissionAsked': true,
      'tileHintDismissed': true,
    });
    expect(status.durationMinutes, 15);
    expect(status.canNotify, isFalse);
    expect(status.notificationPermissionAsked, isTrue);
    expect(status.tileHintDismissed, isTrue);
  });

  test('fromMap eksik süre/bayrak alanlarına güvenli varsayılır', () {
    final status = PrivateDnsStatus.fromMap({'granted': true, 'supported': true});
    expect(status.durationMinutes, 5);
    expect(status.canNotify, isTrue);
    expect(status.notificationPermissionAsked, isFalse);
    expect(status.tileHintDismissed, isFalse);
  });

  test('süre yöntemleri native argümanı taşır', () async {
    final calls = <String, Object?>{};
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls[call.method] = call.arguments;
      return {'granted': true, 'supported': true, 'mode': 'off'};
    });

    final repo = PrivateDnsRepository();
    await repo.setDuration(15);
    await repo.rescheduleResume(30);
    await repo.extendResume(5);

    expect((calls['setDuration']! as Map)['durationMinutes'], 15);
    expect((calls['rescheduleResume']! as Map)['durationMinutes'], 30);
    expect((calls['extendResume']! as Map)['durationMinutes'], 5);
  });

  test('setFlag key ve değeri native\u2019e taşır', () async {
    Object? captured;
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      captured = call.arguments;
      return true;
    });

    await PrivateDnsRepository().setFlag('notification_asked', true);

    final args = captured! as Map;
    expect(args['key'], 'notification_asked');
    expect(args['value'], isTrue);
  });

  test('pause duration argümanını native\u2019e taşır ve resumeAt çözer', () async {
    Object? captured;
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      captured = call.arguments;
      return {'granted': true, 'supported': true, 'mode': 'off', 'resumeAtEpochMs': 1780000000000};
    });

    final status = await PrivateDnsRepository().pause(durationMinutes: 15);

    expect((captured! as Map)['durationMinutes'], 15);
    expect(status.resumeAtEpochMs, 1780000000000);
  });

  test('getEventLog native satırlarını çözümler', () async {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getEventLog');
      return [
        {'epochMs': 1000, 'action': 'pause', 'source': 'tile', 'resumeAtEpochMs': 2000},
      ];
    });

    final events = await PrivateDnsRepository().getEventLog();

    expect(events, hasLength(1));
    expect(events.single['action'], 'pause');
    expect(events.single['resumeAtEpochMs'], 2000);
  });

  test('getEventLog null yanıtını boş listeye çevirir', () async {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(await PrivateDnsRepository().getEventLog(), isEmpty);
  });
}
