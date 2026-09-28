import 'package:flutter/material.dart';

import 'package:zoriapause/core/theme.dart';

/// Kanıt nesnesi — 'Kumanda Plakası' (DESIGN.md, kullanıcı kararı 2026-09-06):
/// tek durum butonu; kol/şartel hareketi YOK. Kompakt plaka: yükseklik
/// içeriğinden gelir (~96dp), boş alanı yutmaz (2026-09-06 kullanıcı notu:
/// "ekranın yarısını kaplıyor"). Durum: mono başlık + Jost durum kelimesi +
/// mono hostname + mono eylem ipucu. Duraklatılmışken plaka ters bloğa
/// döner, sol bakır kontak şeridi parlar. Ayrı durum bandı yok.
/// [heading]/[label] çağırıcıdan BÜYÜK HARF gelir (ARB'de hazır — TR i→İ).
class ControlButton extends StatelessWidget {
  const ControlButton({
    super.key = const Key('home_toggle'),
    required this.heading,
    required this.label,
    required this.hostname,
    required this.hint,
    required this.paused,
    required this.onTap,
  });

  final String heading;
  final String label;
  final String hostname;
  final String hint;
  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.colorScheme.brightness == Brightness.light;
    final plateColor = paused
        ? (isLight ? PanelColors.ink : PanelColors.ivoryText)
        : theme.colorScheme.surface;
    final plateText = paused
        ? (isLight ? PanelColors.ivoryText : PanelColors.ink)
        : theme.colorScheme.onSurface;
    // Bakır kontak şeridi: açıkken dekoratif bakır, duraklatılmışken parlak.
    final stripeColor = paused ? PanelColors.copperBright : theme.colorScheme.primary;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final width = (MediaQuery.sizeOf(context).width * 0.88).clamp(0.0, 420.0);

    return Semantics(
      button: true,
      child: InkResponse(
        onTap: onTap,
        highlightColor: plateText.withValues(alpha: 0.06),
        radius: width / 2,
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: plateColor,
            border: Border.all(color: paused ? plateColor : theme.trim, width: 1.5),
          ),
          child: Row(
            children: [
              Container(width: 6, color: stripeColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: theme.mono(11, weight: FontWeight.w500).copyWith(
                            letterSpacing: 1.6,
                            color: plateText.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.displayLabel(24).copyWith(color: plateText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hostname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.mono(13, weight: FontWeight.w500).copyWith(
                            color: plateText.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: theme.mono(12).copyWith(
                            color: plateText.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
