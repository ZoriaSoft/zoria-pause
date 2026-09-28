import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoriapause/core/constants.dart';
import 'package:zoriapause/core/l10n/generated/app_localizations.dart';
import 'package:zoriapause/core/theme.dart';
import 'package:zoriapause/features/home/presentation/home_screen.dart'
    show TrimLine, showManualProviderDialog;
import 'package:zoriapause/features/pause/application/pause_controller.dart';
import 'package:zoriapause/features/pause/data/private_dns_repository.dart';
import 'package:zoriapause/features/pause/domain/private_dns_status.dart';
import 'package:zoriapause/features/setup/application/shizuku_providers.dart';
import 'package:zoriapause/features/setup/domain/shizuku_gate.dart';

/// Tek yollu kurulum: izin → engelleyici → karo.
/// Biten kurulumda wrench `?ref=guide` ile bu ekranı rehber olarak açar.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(shizukuStatusProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusAsync = ref.watch(pauseControllerProvider);
    final status = statusAsync.value;
    final stepLabel = status == null || !status.onboardingIncomplete
        ? null
        : !status.granted
            ? '1/3'
            : status.needsProvider
                ? '2/3'
                : '3/3';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupTitle),
        actions: [
          if (stepLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  stepLabel,
                  style: theme.mono(12, weight: FontWeight.w500).copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ),
            ),
        ],
      ),
      body: statusAsync.when(
        loading: () => Center(
          child: Text(l10n.statusReading, style: theme.mono(14)),
        ),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorGeneric, style: theme.mono(14))),
        data: (status) {
          if (!status.granted) return _PermitStep(status: status);
          if (status.needsProvider) return const _ProviderStep();
          if (!status.tileHintDismissed) return _TileStep(status: status);
          return const _GuideView();
        },
      ),
    );
  }
}

/// Adım 1 — tek değişen düğme: Play'den kur / Shizuku'yu aç / izin ver.
///
/// SDK kapısı (fleet review F2, 2026-09-21): Shizuku'nun "telefon yeter"
/// yolu wireless debugging gerektirir ve o yalnız Android 11+ (API 30+)
/// mevcut. API 28-29 cihazda Shizuku kartı gösterilmez; kurulum PC/adb
/// komutuna yönlendirilir (dead-end akış kalkar).
class _PermitStep extends ConsumerWidget {
  const _PermitStep({required this.status});

  final PrivateDnsStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final shizuku = ref.watch(shizukuStatusProvider).value;
    final bool phoneOnlyPath = shizukuPhonePathSupported(status.sdkInt);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.setupIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (phoneOnlyPath) ...[
          Text(l10n.setupPathShizukuTitle, style: theme.displayLabel(13)),
          const SizedBox(height: 10),
          const _ShizukuCard(),
          if (shizuku != null && shizuku.installed && !shizuku.running) ...[
            const SizedBox(height: 12),
            Text(l10n.guideStep1Body,
                style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _GuidePage()),
              ),
              icon: Icon(Icons.menu_book_outlined,
                  size: 18, color: theme.accentText),
              label: Text(l10n.setupGuideButton),
            ),
          ),
          const TrimLine(),
          _AdvancedSection(
            title: l10n.setupPathPcTitle,
            body: l10n.setupPathPcSteps,
          ),
          _CommandBlock(command: adbGrantCommand),
          const SizedBox(height: 8),
          _AdvancedSection(
            title: l10n.advancedWirelessTitle,
            body: l10n.setupPathWirelessSteps,
          ),
        ] else ...[
          // API 28-29: telefon-içi kurulum imkânsız — PC/adb tek yol; komut
          // doğrudan öne çıkar, "seçenek" numaralandırması gösterilmez.
          Text(l10n.setupLegacyAndroidNote, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          const TrimLine(),
          const SizedBox(height: 16),
          _CommandBlock(command: adbGrantCommand),
          const SizedBox(height: 12),
          Text(l10n.setupPathPcSteps,
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
        _AdvancedSection(
          title: l10n.devOptionsTitle,
          body: l10n.devOptionsSteps,
        ),
        const SizedBox(height: 16),
        Align(
          child: TextButton.icon(
            onPressed: () async {
              ref.invalidate(pauseControllerProvider);
              ref.invalidate(shizukuStatusProvider);
              await ref.read(pauseControllerProvider.future);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.setupCheckAgain),
          ),
        ),
      ],
    );
  }
}

/// Adım 2 — AdGuard tek dokunuş veya manuel hostname.
class _ProviderStep extends ConsumerWidget {
  const _ProviderStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(pauseControllerProvider.notifier);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.providerCardTitle, style: theme.displayLabel(13)),
        const SizedBox(height: 10),
        Text(l10n.providerCardBody, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => controller.setupProvider(defaultAdGuardHostname),
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: Text(l10n.providerSetupButton),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showManualProviderDialog(context, ref),
            child: Text(l10n.providerManualLink),
          ),
        ),
      ],
    );
  }
}

/// Adım 3 — karo ekleme. Bildirim izni burada, pause'u kesmez.
class _TileStep extends ConsumerWidget {
  const _TileStep({required this.status});

  final PrivateDnsStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(pauseControllerProvider.notifier);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final askNotif = !status.canNotify && !status.notificationPermissionAsked;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.tileHintTitle, style: theme.displayLabel(13)),
        const SizedBox(height: 10),
        Text(l10n.tileHintBody, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        if (askNotif) ...[
          const SizedBox(height: 20),
          const TrimLine(),
          const SizedBox(height: 16),
          Text(l10n.notifPermTitle, style: theme.displayLabel(13)),
          const SizedBox(height: 8),
          Text(l10n.notifPermBody, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await controller.requestNotificationPermission();
                await controller.markNotificationAsked();
              },
              child: Text(l10n.notifPermGrant),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => controller.markNotificationAsked(),
              child: Text(l10n.notifPermLater),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              if (!status.notificationPermissionAsked) {
                await controller.markNotificationAsked();
              }
              await controller.dismissTileHint();
            },
            child: Text(l10n.tileHintDone),
          ),
        ),
      ],
    );
  }
}

/// Kurulum bittikten sonra wrench ile açılan başvuru rehberi.
class _GuideView extends ConsumerWidget {
  const _GuideView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.guideIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        _GuideStep(
          number: '01',
          icon: Icons.wifi,
          title: l10n.guideStep1Title,
          body: l10n.guideStep1Body,
          image: 'assets/guide/guide_01.png',
        ),
        _GuideStep(
          number: '02',
          icon: Icons.ad_units,
          title: l10n.guideStep2Title,
          body: l10n.guideStep2Body,
          image: 'assets/guide/guide_02.png',
        ),
        _GuideStep(
          number: '03',
          icon: Icons.wifi_tethering,
          title: l10n.guideStep3Title,
          body: l10n.guideStep3Body,
          image: 'assets/guide/guide_03.png',
        ),
        _GuideStep(
          number: '04',
          icon: Icons.shop,
          title: l10n.guideStep4Title,
          body: l10n.guideStep4Body,
          image: 'assets/guide/guide_04.png',
          action: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(privateDnsRepositoryProvider).openShizukuInPlay(),
              icon: Icon(Icons.open_in_new, size: 16, color: theme.accentText),
              label: Text(l10n.shizukuInstallButton),
            ),
          ),
        ),
        _GuideStep(
          number: '05',
          icon: Icons.play_arrow,
          title: l10n.guideStep5Title,
          body: l10n.guideStep5Body,
          image: 'assets/guide/guide_05.png',
        ),
        _GuideStep(
          number: '06',
          icon: Icons.check_circle_outline,
          title: l10n.guideStep6Title,
          body: l10n.guideStep6Body,
          image: 'assets/guide/guide_06.png',
        ),
        _GuideStep(
          number: '07',
          icon: Icons.bolt,
          title: l10n.guideStep7Title,
          body: l10n.guideStep7Body,
          image: 'assets/guide/guide_07.png',
        ),
        const TrimLine(),
        const SizedBox(height: 10),
        Text(
          l10n.guideRebootNote,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.guideTroubleNote,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

/// Kurulum sırasında açılan rehber sayfası — `_GuideView`'i AppBar'lı
/// Scaffold'a sarar; router'dan bağımsız push ile gelir.
class _GuidePage extends StatelessWidget {
  const _GuidePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTabGuide)),
      body: const _GuideView(),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.image,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: theme.mono(22, weight: FontWeight.w600).copyWith(
                  color: theme.accentText,
                ),
          ),
          const SizedBox(width: 14),
          Icon(icon, size: 22, color: theme.colorScheme.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.displayLabel(14)),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                if (image != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(image!, fit: BoxFit.fitWidth),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 6), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 14),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: PanelColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupCommandHeader,
            style: theme.mono(11, weight: FontWeight.w500).copyWith(
                  letterSpacing: 1.6,
                  color: PanelColors.ivoryText.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            command,
            style: theme.mono(13, weight: FontWeight.w500)
                .copyWith(color: PanelColors.ivoryText),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: command));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.setupCopied)));
                }
              },
              icon: Icon(Icons.copy, size: 18, color: PanelColors.copperBright),
              label: Text(l10n.setupCopy),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShizukuCard extends ConsumerWidget {
  const _ShizukuCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final repo = ref.watch(privateDnsRepositoryProvider);

    return ref.watch(shizukuStatusProvider).when(
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (status) {
            if (!status.installed) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.shizukuNeedInstall, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => repo.openShizukuInPlay(),
                      icon: const Icon(Icons.shop, size: 18),
                      label: Text(l10n.shizukuInstallButton),
                    ),
                  ),
                ],
              );
            }
            if (!status.running) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.shizukuStartHint, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => repo.openShizukuApp(),
                      icon: const Icon(Icons.launch, size: 18),
                      label: Text(l10n.shizukuOpenButton),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.shizukuReady, style: theme.mono(12).copyWith(color: muted)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final started = await repo.shizukuGrant();
                      ref.invalidate(shizukuStatusProvider);
                      if (!started && context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.shizukuGrantFailed)),
                          );
                      }
                    },
                    icon: const Icon(Icons.bolt, size: 18),
                    label: Text(l10n.shizukuGrantButton),
                  ),
                ),
              ],
            );
          },
        );
  }
}
