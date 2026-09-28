import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme.dart';
import 'features/pause/application/pause_controller.dart';

// Crash reporting (Sentry) is opt-in at build time:
//   flutter run --dart-define=SENTRY_DSN=https://...@....ingest.sentry.io/...
// Without a DSN the app simply runs without reporting.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const _appName = 'zoria-pause';

Future<void> main() async {
  // Release builds request no INTERNET permission (product promise: fully
  // on-device). Sentry would silently drop without it, so we don't init it
  // in release at all. Debug/profile builds add INTERNET via the Flutter
  // manifest — reporting goes out there when a DSN is provided.
  if (kReleaseMode || _sentryDsn.isEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: ZoriaPauseApp()));
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.2;
    },
    appRunner: () async {
      Sentry.configureScope((scope) => scope.setTag('app', _appName));
      runApp(const ProviderScope(child: ZoriaPauseApp()));
    },
  );
}

class ZoriaPauseApp extends ConsumerStatefulWidget {
  const ZoriaPauseApp({super.key});

  @override
  ConsumerState<ZoriaPauseApp> createState() => _ZoriaPauseAppState();
}

class _ZoriaPauseAppState extends ConsumerState<ZoriaPauseApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Öndeyken grant/settings değişmiş olabilir — dönüşte durumu tazele.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(pauseControllerProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
