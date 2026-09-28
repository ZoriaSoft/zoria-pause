import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoriapause/core/constants.dart';
import 'package:zoriapause/features/pause/application/event_log_providers.dart';
import 'package:zoriapause/features/pause/data/private_dns_repository.dart';
import 'package:zoriapause/features/pause/domain/private_dns_status.dart';

/// Uygulama ömrü boyunca yaşar — P6 kuralı (async iş başlatan controller
/// dispose edilmez; Riverpod 3'te manuel provider'lar default keepAlive'dır).
/// Süre seçimi bellekte DEĞİL: status.durationMinutes native tek kaynaktır
/// (tile aynı değeri okur); seçimler [setDuration] ile kalıcı yazılır.
class PauseController extends AsyncNotifier<PrivateDnsStatus> {
  @override
  Future<PrivateDnsStatus> build() {
    final repo = ref.read(privateDnsRepositoryProvider);
    // ContentObserver köprüsü: tile dışından (sistem ayarları) değişim.
    repo.listen(_onExternalChange);
    ref.onDispose(repo.cancelListen);
    return repo.getStatus();
  }

  Future<void> pause() async {
    final repo = ref.read(privateDnsRepositoryProvider);
    // durationMinutes=null → native kalıcı seçim (tile ile aynı kaynak).
    state = await AsyncValue.guard(() => repo.pause());
    ref.invalidate(eventLogSyncProvider);
  }

  Future<void> resume() async {
    final repo = ref.read(privateDnsRepositoryProvider);
    state = await AsyncValue.guard(repo.resume);
    ref.invalidate(eventLogSyncProvider);
  }

  /// Süre çipi (duraklatma kapalı): kalıcı seçim — sonraki pause ve tile bunu
  /// kullanır.
  Future<void> setDuration(int minutes) async {
    final repo = ref.read(privateDnsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.setDuration(minutes));
  }

  /// Süre çipi (duraklatma açık): şu andan itibaren N dk yeniden planla.
  /// Elle kapatılmış DNS'te (plansız pause) plan kurar.
  Future<void> rescheduleResume(int minutes) async {
    final repo = ref.read(privateDnsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.rescheduleResume(minutes));
    ref.invalidate(eventLogSyncProvider);
  }

  /// [+5 dk]: kalan sürenin üzerine ekle (panel bandı / bildirim aksiyonu).
  Future<void> extendResume(int minutes) async {
    final repo = ref.read(privateDnsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.extendResume(minutes));
    ref.invalidate(eventLogSyncProvider);
  }

  /// Engelleyici DNS kur (AdGuard tek dokunuş / manuel hostname).
  Future<void> setupProvider(String hostname) async {
    final repo = ref.read(privateDnsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.setupProvider(hostname));
    ref.invalidate(eventLogSyncProvider);
  }

  /// API 33+ bildirim izni — bilgi kartının [İZİN VER] yanıtından çağrılır.
  Future<void> requestNotificationPermission() async {
    await ref.read(privateDnsRepositoryProvider).ensureNotificationPermission();
  }

  /// Bildirim izni kartı yanıtlandı — bir daha gösterilmez.
  Future<void> markNotificationAsked() async {
    await _setFlag(flagNotificationAsked, notificationPermissionAsked: true);
  }

  /// Tile rehberi kartı kapatıldı.
  Future<void> dismissTileHint() async {
    await _setFlag(flagTileHintDismissed, tileHintDismissed: true);
  }

  Future<void> _setFlag(
    String key, {
    bool? notificationPermissionAsked,
    bool? tileHintDismissed,
  }) async {
    final repo = ref.read(privateDnsRepositoryProvider);
    await repo.setFlag(key, true);
    // Loading flash'ı olmadan yerel güncelleme.
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          notificationPermissionAsked: notificationPermissionAsked,
          tileHintDismissed: tileHintDismissed,
        ),
      );
    }
  }

  /// Sadece veriyi tazeler — loading flash'ı olmadan.
  Future<void> _onExternalChange() async {
    try {
      state = AsyncData(await ref.read(privateDnsRepositoryProvider).getStatus());
      ref.invalidate(eventLogSyncProvider);
    } on Exception {
      // Eski durum ekranda kalır; bir sonraki değişimde tekrar denenir.
    }
  }
}

final pauseControllerProvider =
    AsyncNotifierProvider<PauseController, PrivateDnsStatus>(PauseController.new);
