import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoriapause/features/pause/data/private_dns_repository.dart';
import 'package:zoriapause/features/setup/domain/shizuku_status.dart';

/// Setup ekranının Shizuku durumu — ekran dışındayken ölü olması yeterli
/// (autoDispose); "Yeniden kontrol et" ve statusChanged ile tazelenir.
final shizukuStatusProvider = FutureProvider.autoDispose<ShizukuStatus>((ref) {
  return ref.watch(privateDnsRepositoryProvider).shizukuStatus();
});
