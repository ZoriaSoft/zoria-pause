import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zoriapause/core/constants.dart';
import 'package:zoriapause/main.dart';

void main() {
  const channel = MethodChannel('zoriasoft/zoria_pause');

  var grant = true;
  var supported = true;
  // SDK gate (fleet review F2): native statusMap'ten gelen seviye. Varsayılan
  // test değeri Android 15 — telefon-içi Shizuku yolu açık.
  var sdkInt = 35;
  var paused = false;
  var auto = false;
  var scheduled = true;
  String? specifierValue = 'dns.adguard.com';
  var canNotify = true;
  var notifAsked = true;
  var tileHintDismissed = true;
  var selectedDuration = 5;
  Object? capturedPauseArgs;
  Object? capturedSetDurationArgs;
  Object? capturedRescheduleArgs;
  Object? capturedExtendArgs;
  String? capturedSetupHostname;
  var shizukuInstalled = false;
  var shizukuRunning = false;
  var shizukuGrantCalls = 0;
  var permissionCalls = 0;
  const resumeAtMs = 1780000000000;

  Map<Object?, Object?> statusMap() => {
        'granted': grant,
        'supported': supported,
        'sdkInt': sdkInt,
        'mode': paused ? 'off' : (auto ? 'opportunistic' : 'hostname'),
        'specifier': specifierValue,
        'resumeAtEpochMs': paused && scheduled ? resumeAtMs : null,
        'durationMinutes': selectedDuration,
        'canNotify': canNotify,
        'notificationPermissionAsked': notifAsked,
        'tileHintDismissed': tileHintDismissed,
      };

  Map<Object?, Object?> shizukuMap() => {
        'installed': shizukuInstalled,
        'running': shizukuRunning,
        'permissionGranted': shizukuRunning,
      };

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView;
    view!.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.reset);
    grant = true;
    supported = true;
    sdkInt = 35;
    paused = false;
    auto = false;
    scheduled = true;
    specifierValue = 'dns.adguard.com';
    canNotify = true;
    notifAsked = true;
    tileHintDismissed = true;
    selectedDuration = 5;
    capturedPauseArgs = null;
    capturedSetDurationArgs = null;
    capturedRescheduleArgs = null;
    capturedExtendArgs = null;
    capturedSetupHostname = null;
    shizukuInstalled = false;
    shizukuRunning = false;
    shizukuGrantCalls = 0;
    permissionCalls = 0;
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async => null);
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getStatus':
          return statusMap();
        case 'pause':
          paused = true;
          capturedPauseArgs = call.arguments;
          return statusMap();
        case 'resume':
          paused = false;
          return statusMap();
        case 'setupProvider':
          capturedSetupHostname = (call.arguments as Map)['hostname'] as String?;
          specifierValue = capturedSetupHostname;
          auto = false;
          paused = false;
          return statusMap();
        case 'setDuration':
          capturedSetDurationArgs = call.arguments;
          selectedDuration = (call.arguments as Map)['durationMinutes'] as int;
          return statusMap();
        case 'rescheduleResume':
          capturedRescheduleArgs = call.arguments;
          return statusMap();
        case 'extendResume':
          capturedExtendArgs = call.arguments;
          scheduled = true;
          return statusMap();
        case 'setFlag':
          final key = (call.arguments as Map)['key'] as String?;
          final value = (call.arguments as Map)['value'] == true;
          if (key == flagNotificationAsked) notifAsked = value;
          if (key == flagTileHintDismissed) tileHintDismissed = value;
          return true;
        case 'getEventLog':
          return const [];
        case 'ensureNotificationPermission':
          permissionCalls++;
          return true;
        case 'shizukuStatus':
          return shizukuMap();
        case 'shizukuGrant':
          shizukuGrantCalls++;
          return true;
        case 'openShizukuInPlay':
        case 'openShizukuApp':
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> sendStatusChanged() async {
    await TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('statusChanged')),
      (_) {},
    );
  }

  group('ana panel', () {
    testWidgets('koruma açık durumu gösterir ve kesici duraklatır', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('Zoria Pause'), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
      expect(find.text('dns.adguard.com'), findsOneWidget);
      expect(find.text('v$appVersion'), findsOneWidget);
      expect(kAppVersion.startsWith('$appVersion+'), isTrue);
      expect(find.text('PRIVATE DNS'), findsNothing);

      await tester.tap(find.byKey(const Key('home_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect((capturedPauseArgs! as Map)['durationMinutes'], isNull);
      expect(find.textContaining('Resumes at'), findsOneWidget);
      expect(find.text('dns.adguard.com'), findsOneWidget);
    });

    testWidgets('koruma açıkken süre seçici görünür ve seçim kalıcı yazılır', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('AUTO-RESUME'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);

      await tester.tap(find.text('15 min'));
      await tester.pumpAndSettle();
      expect((capturedSetDurationArgs! as Map)['durationMinutes'], 15);
    });

    testWidgets('statusChanged olayı ekranı canlı tazeler', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();
      expect(find.text('ON'), findsOneWidget);

      paused = true;
      await sendStatusChanged();
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.textContaining('Resumes at'), findsOneWidget);
    });

    testWidgets('bilgi kartı kapalı başlar, açılınca dürüst içeriği gösterir', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('WHAT GETS BLOCKED?'), findsOneWidget);
      expect(find.text('DOESN\'T BLOCK'), findsNothing);

      await tester.tap(find.text('WHAT GETS BLOCKED?'));
      await tester.pumpAndSettle();

      expect(find.text('BLOCKS'), findsOneWidget);
      expect(find.text('DOESN\'T BLOCK'), findsOneWidget);
      expect(find.text('HOW IT WORKS'), findsOneWidget);
    });

    testWidgets('grantlıyken app bar rehber girişi setup rehberini açar', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Setup guide'));
      await tester.pumpAndSettle();

      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('Connect to a Wi-Fi network'), findsOneWidget);
      expect(find.textContaining('phone restarts'), findsOneWidget);
    });

    testWidgets('kesiciye ikinci dokunuş geri açar', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_toggle')));
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home_toggle')));
      await tester.pumpAndSettle();
      expect(find.text('ON'), findsOneWidget);
      expect(find.textContaining('Resumes at'), findsNothing);
    });

    testWidgets('desteklenmeyen cihazda uyarı basar, setup gate devre dışı', (tester) async {
      supported = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Android 9+'), findsOneWidget);
      expect(find.byKey(const Key('home_toggle')), findsNothing);
      expect(find.text('Setup'), findsNothing);
    });

    testWidgets('opportunistic mod dürüstçe AUTO der, ON DEMEZ', (tester) async {
      auto = true;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('AUTO'), findsOneWidget);
      expect(find.text('ON'), findsNothing);
      expect(find.text('PROTECTION ON'), findsNothing);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('plansız pause (elle kapatılmış DNS) dürüst not gösterir', (tester) async {
      paused = true;
      scheduled = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.textContaining('Resumes at'), findsNothing);
      expect(find.textContaining('No auto-resume'), findsOneWidget);
      expect(find.text('REPLAN'), findsOneWidget);
      await tester.tap(find.text('15 min'));
      await tester.pumpAndSettle();
      expect((capturedRescheduleArgs! as Map)['durationMinutes'], 15);
    });

    testWidgets('duraklatılmışken çipler yeniden planlar, bant uzatır', (tester) async {
      paused = true;
      scheduled = true;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('REPLAN'), findsOneWidget);
      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();
      expect((capturedRescheduleArgs! as Map)['durationMinutes'], 30);

      expect(find.text('ENDS SOON'), findsOneWidget);
      await tester.tap(find.text('+5 MIN'));
      await tester.pumpAndSettle();
      expect((capturedExtendArgs! as Map)['durationMinutes'], 5);
    });

    testWidgets('ilk pause bildirim kartı çıkarmaz', (tester) async {
      canNotify = false;
      notifAsked = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.textContaining('NOTIFICATION PERMISSION'), findsNothing);
    });
  });

  group('karo adımı (bildirim + bitir)', () {
    testWidgets('ilk açılışta karo adımı görünür, TAMAM panele döner', (tester) async {
      tileHintDismissed = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('FOR ONE-TAP CONTROL'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);

      await tester.tap(find.text('DONE, ADDED IT'));
      await tester.pumpAndSettle();

      expect(tileHintDismissed, isTrue);
      expect(find.text('ON'), findsOneWidget);
      expect(find.text('FOR ONE-TAP CONTROL'), findsNothing);
    });

    testWidgets('karo adımında İZİN VER sistem iznini ister, pause etmez', (tester) async {
      tileHintDismissed = false;
      canNotify = false;
      notifAsked = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('NOTIFICATION PERMISSION'), findsOneWidget);
      await tester.tap(find.text('ALLOW'));
      await tester.pumpAndSettle();

      expect(permissionCalls, 1);
      expect(notifAsked, isTrue);
      expect(find.text('FOR ONE-TAP CONTROL'), findsOneWidget);
      expect(paused, isFalse);
    });
  });

  group('engelleyici kurma (AdGuard)', () {
    testWidgets('engelleyici yoksa adım 2 çıkar; tek dokunuş AdGuard kurar', (tester) async {
      auto = true;
      specifierValue = null;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('AD BLOCKING NOT SET UP'), findsOneWidget);
      expect(find.text('SET UP ADGUARD'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      await tester.tap(find.text('SET UP ADGUARD'));
      await tester.pumpAndSettle();

      expect(capturedSetupHostname, 'dns.adguard.com');
      expect(find.text('AD BLOCKING NOT SET UP'), findsNothing);
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('hostname modu + specifier varsa kurulum adımı çıkmaz', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('AD BLOCKING NOT SET UP'), findsNothing);
      expect(find.text('ON'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('manuel DNS diyaloğu geçerli adresi kurar, geçersizi reddeder', (tester) async {
      auto = true;
      specifierValue = null;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Enter it manually'));
      await tester.pumpAndSettle();
      expect(find.text('DNS ADDRESS'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'geçersiz adres');
      await tester.tap(find.text('SET UP'));
      await tester.pumpAndSettle();
      expect(capturedSetupHostname, isNull);
      expect(find.textContaining('Enter a valid address'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '94.140.14.14');
      await tester.tap(find.text('SET UP'));
      await tester.pumpAndSettle();
      expect(capturedSetupHostname, isNull);
      expect(find.textContaining('Enter a valid address'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'dns.example.com');
      await tester.tap(find.text('SET UP'));
      await tester.pumpAndSettle();
      expect(capturedSetupHostname, 'dns.example.com');
    });
  });

  group('süresiz duraklatma', () {
    testWidgets('Süresiz çipi seçimi kalıcı 0 olarak yazılır', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('No timer'), findsOneWidget);
      await tester.tap(find.text('No timer'));
      await tester.pumpAndSettle();
      expect((capturedSetDurationArgs! as Map)['durationMinutes'], 0);
    });

    testWidgets('duraklatılmışken Süresiz çipi planı kaldırır (reschedule 0)', (tester) async {
      paused = true;
      scheduled = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No timer'));
      await tester.pumpAndSettle();
      expect((capturedRescheduleArgs! as Map)['durationMinutes'], 0);
    });
  });

  group('kurulum ekranı', () {
    testWidgets('grant yoksa izin adımına yönlendirir ve komutu gösterir', (tester) async {
      grant = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.textContaining('OPTION 1'), findsOneWidget);
      expect(find.textContaining('OPTION 2'), findsOneWidget);
      expect(find.textContaining('pm grant com.zoriasoft.zoriapause'), findsOneWidget);
      expect(find.text('Copy command'), findsOneWidget);

      await tester.ensureVisible(find.text('Copy command'));
      await tester.tap(find.text('Copy command'));
      await tester.pumpAndSettle();
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('grant geldikten sonra yeniden kontrol sonraki adıma/panele döner', (tester) async {
      grant = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();
      expect(find.text('Setup'), findsOneWidget);

      grant = true;
      await tester.ensureVisible(find.text('Check again'));
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();

      expect(find.text('ON'), findsOneWidget);
      expect(find.text('Setup'), findsNothing);
    });

    testWidgets('Shizuku kurulu değilse Play Store butonu yönlendirir', (tester) async {
      grant = false;
      shizukuInstalled = false;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('small helper app'), findsOneWidget);
      expect(find.text('INSTALL FROM PLAY STORE'), findsOneWidget);
      expect(find.text('ALLOW'), findsNothing);

      var opened = false;
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openShizukuInPlay') opened = true;
        return true;
      });
      await tester.tap(find.text('INSTALL FROM PLAY STORE'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });

    testWidgets('Shizuku kurulu ama kapalıysa AÇ butonu gösterilir', (tester) async {
      grant = false;
      shizukuInstalled = true;
      shizukuRunning = false;
      var opened = false;
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openShizukuApp') opened = true;
        return call.method == 'shizukuStatus'
            ? shizukuMap()
            : call.method == 'getStatus'
                ? statusMap()
                : true;
      });

      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('not started yet'), findsOneWidget);
      expect(find.text('OPEN SHIZUKU'), findsOneWidget);
      expect(find.textContaining('Wi-Fi'), findsWidgets);

      await tester.tap(find.text('OPEN SHIZUKU'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });

    testWidgets('Shizuku çalışırken tek dokunuş akışı başlar', (tester) async {
      grant = false;
      shizukuInstalled = true;
      shizukuRunning = true;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.text('Shizuku is ready. Permission can be granted with one tap.'),
          findsOneWidget);

      await tester.tap(find.text('ALLOW'));
      await tester.pumpAndSettle();
      expect(shizukuGrantCalls, 1);
    });

    testWidgets('API 28-29 Shizuku kartını göstermez, PC/adb yoluna yönlendirir',
        (tester) async {
      grant = false;
      sdkInt = 29;
      shizukuInstalled = true;
      shizukuRunning = true;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      // Dead-end telefon-içi yol gizli: seçenek başlıkları ve Shizuku UI yok.
      expect(find.textContaining('OPTION 1'), findsNothing);
      expect(find.textContaining('OPTION 2'), findsNothing);
      expect(find.text('ALLOW'), findsNothing);
      expect(find.text('INSTALL FROM PLAY STORE'), findsNothing);
      // PC/adb yönlendirme notu + komut öne çıkar.
      expect(find.textContaining('Android 11 or newer'), findsOneWidget);
      expect(find.textContaining('pm grant com.zoriasoft.zoriapause'), findsOneWidget);
      expect(find.text('Copy command'), findsOneWidget);
    });

    testWidgets('API 30 sınırında Shizuku kartı görünür', (tester) async {
      grant = false;
      sdkInt = 30;
      shizukuInstalled = true;
      shizukuRunning = true;
      await tester.pumpWidget(const ProviderScope(child: ZoriaPauseApp()));
      await tester.pumpAndSettle();

      expect(find.textContaining('OPTION 1'), findsOneWidget);
      expect(find.text('Shizuku is ready. Permission can be granted with one tap.'),
          findsOneWidget);
      expect(find.textContaining('Android 11 or newer'), findsNothing);
    });
  });
}
