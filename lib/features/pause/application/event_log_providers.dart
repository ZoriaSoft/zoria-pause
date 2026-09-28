import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoriapause/core/db/app_database.dart';
import 'package:zoriapause/features/pause/data/private_dns_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Native event log → Drift senkronu. Native PauseEventLog TEK KAYNAK (tile ve
/// auto-resume Dart'sız çalışabildiği için); her senkron tabloyu yeniden
/// yükler. Pause/resume sonrası ve statusChanged'de invalidate edilir.
final eventLogSyncProvider = FutureProvider<void>((ref) async {
  final events = await ref.watch(privateDnsRepositoryProvider).getEventLog();
  await ref.watch(appDatabaseProvider).replaceAllEvents(events);
});

/// "Bu hafta N kez duraklattın" mini özeti — PLAN'daki tek istatistik.
final weeklyPauseCountProvider = StreamProvider<int>((ref) {
  final sync = ref.watch(eventLogSyncProvider);
  if (!sync.hasValue) return const Stream<int>.empty();
  return ref.watch(appDatabaseProvider).weeklyPauseCount();
});
