import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Pause/resume olay geçmişi. Native PauseEventLog TEK KAYNAKTIR (tile ve
/// auto-resume Dart'sız çalışır); bu tablo her senkronda ondan yeniden
/// yüklenir ve sorgular burada koşar ("bu hafta N kez" mini özeti).
class EventLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get epochMs => integer()();
  TextColumn get action => text()(); // pause | resume
  TextColumn get source => text()(); // app | tile | auto | notification
  TextColumn get mode => text().nullable()();
  TextColumn get specifier => text().nullable()();
  IntColumn get resumeAtEpochMs => integer().nullable()();
}

@DriftDatabase(tables: [EventLogEntries])
class AppDatabase extends _$AppDatabase {
  // drift_flutter: getApplicationSupportDirectory/zoria_pause.sqlite —
  // NativeDatabase+path_provider eldesiyle aynı dosya, mevcut kurulumlar korunur.
  AppDatabase() : super(driftDatabase(name: 'zoria_pause'));

  @override
  int get schemaVersion => 1;

  /// Native log yeniden yükleme — native taraf tek kaynak, tablo replace edilir.
  Future<void> replaceAllEvents(List<Map<Object?, Object?>> raw) {
    return transaction(() async {
      await delete(eventLogEntries).go();
      await batch((batch) {
        batch.insertAll(
          eventLogEntries,
          raw.map(_companionFromMap).toList(),
        );
      });
    });
  }

  /// PLAN dürüstlük notu: "bu hafta 12 kez duraklattın" mini özeti — başka grafik yok.
  Stream<int> weeklyPauseCount() {
    final since =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final query = select(eventLogEntries)
      ..where(
        (entry) =>
            entry.action.equals('pause') & entry.epochMs.isBiggerThanValue(since),
      );
    return query.watch().map((rows) => rows.length);
  }

  EventLogEntriesCompanion _companionFromMap(Map<Object?, Object?> raw) {
    return EventLogEntriesCompanion.insert(
      epochMs: raw['epochMs'] as int? ?? 0,
      action: raw['action'] as String? ?? '',
      source: raw['source'] as String? ?? '',
      mode: Value(raw['mode'] as String?),
      specifier: Value(raw['specifier'] as String?),
      resumeAtEpochMs: Value(raw['resumeAtEpochMs'] as int?),
    );
  }
}
