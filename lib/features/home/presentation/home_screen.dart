import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zoriapause/core/constants.dart';
import 'package:zoriapause/core/l10n/generated/app_localizations.dart';
import 'package:zoriapause/core/theme.dart';
import 'package:zoriapause/features/pause/application/event_log_providers.dart';
import 'package:zoriapause/features/pause/application/pause_controller.dart';
import 'package:zoriapause/features/pause/domain/private_dns_status.dart';
import 'package:zoriapause/features/home/presentation/widgets/control_button.dart';

/// 'Anahtar Panosu' — Operate paterni. Kurulum kartları yok: izin /
/// engelleyici / karo sihirbazda biter. Pano = plaka (hostname dahil) +
/// süre + bilgi + log. Rehber: app bar, `?ref=guide`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(pauseControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeSetupTooltip,
            onPressed: () => context.push('/setup?ref=guide'),
            icon: const Icon(Icons.build_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statusAsync.when(
        loading: () => Center(
          child: Text(l10n.statusReading, style: Theme.of(context).mono(14)),
        ),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorGeneric, style: Theme.of(context).mono(14))),
        data: (status) => _Panel(status: status),
      ),
    );
  }
}

/// Manuel DNS adresi diyaloğu — kurulum adım 2'den de çağrılır.
Future<void> showManualProviderDialog(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: theme.trim, width: 1.5),
      ),
      child: _ManualProviderForm(
        onSubmit: (hostname) {
          Navigator.of(dialogContext).pop();
          ref.read(pauseControllerProvider.notifier).setupProvider(hostname);
        },
      ),
    ),
  );
}

/// Diyalog formu — controller yaşam döngüsü State'e ait (element
/// unmount edilince dispose; kapanış animasyonuyla yarışmaz).
class _ManualProviderForm extends StatefulWidget {
  const _ManualProviderForm({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_ManualProviderForm> createState() => _ManualProviderFormState();
}

class _ManualProviderFormState extends State<_ManualProviderForm> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.providerManualTitle, style: theme.displayLabel(13)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            style: theme.mono(14),
            decoration: InputDecoration(
              hintText: l10n.providerManualHint,
              hintStyle: theme.mono(13).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.trim, width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
              errorText: null,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: theme.mono(12).copyWith(color: theme.accentText),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.providerManualCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final value = _controller.text.trim();
                  if (!_looksLikeHostname(value)) {
                    setState(() => _error = l10n.providerManualInvalid);
                    return;
                  }
                  widget.onSubmit(value);
                },
                child: Text(l10n.providerManualApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Yaygın DoT hostname formu: etiketler + en az bir nokta; boşluk/Türkçe
/// karakter kabul edilmez. Tam RFC doğrulaması değil — yazım kazası koruması.
bool _looksLikeHostname(String value) {
  // Ham IPv4 Private DNS'i bozar; sistem DoT el sıkışması yalnız hostname kabul eder.
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(value)) return false;
  final regex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$');
  return regex.hasMatch(value);
}

class _Panel extends ConsumerWidget {
  const _Panel({required this.status});

  final PrivateDnsStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(pauseControllerProvider.notifier);
    final specifier = status.specifier;
    final hostname =
        specifier == null || specifier.isEmpty ? l10n.statusNoHostname : specifier;

    if (!status.supported) {
      return _CenteredMessage(message: l10n.errorUnsupported);
    }
    if (!status.granted) {
      return _CenteredMessage(message: l10n.errorNotGranted);
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: ControlButton(
                heading: l10n.controlHeading,
                label: switch (status.mode) {
                  'off' => l10n.controlPaused,
                  'hostname' => l10n.controlOn,
                  _ => l10n.controlAuto,
                },
                hostname: hostname,
                hint: status.isPaused ? l10n.controlTapResume : l10n.controlTapPause,
                paused: status.isPaused,
                onTap: status.isPaused ? controller.resume : controller.pause,
              ),
            ),
            const SizedBox(height: 24),
            const TrimLine(),
            if (status.isPaused && status.resumeAtEpochMs != null) ...[
              _PausedSection(
                resumeAtEpochMs: status.resumeAtEpochMs!,
                canNotify: status.canNotify,
              ),
              _ReminderBand(
                resumeAtEpochMs: status.resumeAtEpochMs!,
                onExtend: () => controller.extendResume(5),
              ),
              _DurationSection(
                paused: true,
                selected: status.durationMinutes,
                onPick: controller.rescheduleResume,
              ),
            ] else if (status.isPaused)
              ...[
                _UnscheduledNote(),
                _DurationSection(
                  paused: true,
                  selected: status.durationMinutes,
                  onPick: controller.rescheduleResume,
                ),
              ]
            else
              _DurationSection(
                paused: false,
                selected: status.durationMinutes,
                onPick: controller.setDuration,
              ),
            const TrimLine(),
            const _InfoCard(),
            const TrimLine(),
            const _LogLine(),
          ],
        ),
      ),
    );
  }
}

class _PausedSection extends StatelessWidget {
  const _PausedSection({required this.resumeAtEpochMs, required this.canNotify});

  final int resumeAtEpochMs;
  final bool canNotify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final time = TimeOfDay.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(resumeAtEpochMs),
    ).format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${l10n.resumeAtLabel}: $time', style: theme.mono(14, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            l10n.autoResumeNote,
            textAlign: TextAlign.center,
            style: theme.mono(12).copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.honestDelayNote,
            textAlign: TextAlign.center,
            style: theme.mono(12).copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          if (!canNotify) ...[
            const SizedBox(height: 2),
            Text(
              l10n.notifOffNote,
              textAlign: TextAlign.center,
              style: theme.mono(12).copyWith(color: theme.accentText),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnscheduledNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        l10n.unscheduledNote,
        textAlign: TextAlign.center,
        style: theme.mono(12).copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

class _DurationSection extends StatelessWidget {
  const _DurationSection({
    required this.paused,
    required this.selected,
    required this.onPick,
  });

  final bool paused;
  final int selected;
  final void Function(int minutes) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text(
            paused ? l10n.durationRelabel : l10n.durationLabel,
            style: theme.mono(11, weight: FontWeight.w500).copyWith(
                  letterSpacing: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final minutes in [5, 15, 30, 0])
                Expanded(
                  child: _DurationChip(
                    label: minutes == 0
                        ? l10n.durationForever
                        : '$minutes ${l10n.minutesShort}',
                    selected: minutes == selected,
                    onTap: () => onPick(minutes),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inverted = selected;
    final background = inverted ? theme.colorScheme.onSurface : Colors.transparent;
    final foreground = inverted ? theme.colorScheme.surface : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: inverted ? background : theme.trim),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.mono(12, weight: FontWeight.w500).copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatefulWidget {
  const _InfoCard();

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(child: Text(l10n.infoTitle, style: theme.displayLabel(12))),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            _InfoBlock(label: l10n.infoBlocksLabel, body: l10n.infoBlocks),
            _InfoBlock(label: l10n.infoLimitsLabel, body: l10n.infoLimits),
            _InfoBlock(label: l10n.infoHowLabel, body: l10n.infoHow),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.mono(10, weight: FontWeight.w600).copyWith(
                  letterSpacing: 1.4,
                  color: theme.accentText,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderBand extends StatefulWidget {
  const _ReminderBand({required this.resumeAtEpochMs, required this.onExtend});

  final int resumeAtEpochMs;
  final VoidCallback onExtend;

  @override
  State<_ReminderBand> createState() => _ReminderBandState();
}

class _ReminderBandState extends State<_ReminderBand> {
  static final _lead = const Duration(minutes: 1);
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_ReminderBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resumeAtEpochMs != widget.resumeAtEpochMs) {
      _timer?.cancel();
      _visible = false;
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    final remaining =
        DateTime.fromMillisecondsSinceEpoch(widget.resumeAtEpochMs)
            .difference(DateTime.now()) -
            _lead;
    if (remaining <= Duration.zero) {
      _visible = true;
      return;
    }
    _timer = Timer(remaining, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isLight = theme.colorScheme.brightness == Brightness.light;
    final background = isLight ? PanelColors.ink : PanelColors.ivoryText;
    final foreground = isLight ? PanelColors.ivoryText : PanelColors.ink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: background,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.reminderBandTitle,
                style: theme.mono(12, weight: FontWeight.w600).copyWith(color: foreground),
              ),
            ),
            TextButton(
              onPressed: widget.onExtend,
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: Text(l10n.reminderBandExtend),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogLine extends ConsumerWidget {
  const _LogLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ref.watch(weeklyPauseCountProvider).when(
                  data: (count) =>
                      Text(l10n.weeklyCount(count), style: theme.mono(12).copyWith(color: muted)),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
          ),
          const SizedBox(width: 12),
          Text('v$appVersion', style: theme.mono(12).copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: theme.mono(14), textAlign: TextAlign.center),
      ),
    );
  }
}

/// 1px deco trim çizgi — bölmeleri çizen pano dili.
class TrimLine extends StatelessWidget {
  const TrimLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Theme.of(context).trim);
  }
}
