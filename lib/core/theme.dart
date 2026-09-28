import 'package:flutter/material.dart';

/// 'Anahtar Panosu' token seti — DESIGN.md sözleşmesi (2026-09-05 commit).
/// Fildişi + mürekkep + bakır; Jost display + sistem Roboto body + IBM Plex
/// Mono. Gradyan YOK, tek aksan (bakır), durum şekil + metin + konum ile
/// verilir. Ekran kodundan inline hex/font YASAK — yalnız bu dosya.
abstract final class PanelColors {
  static const ivory = Color(0xFFF2EDE1); // açık zemin (pano)
  static const ivoryText = Color(0xFFF0EBDF); // koyu zeminde metin
  static const ink = Color(0xFF222420); // açık zeminde metin / ters blok
  static const soot = Color(0xFF1B1A17); // koyu zemin (pano gece)
  static const copper = Color(0xFFB4653A); // bakır kontak (açık tema)
  static const copperBright = Color(0xFFC87A4E); // bakır (koyu tema / pause)
  static const copperDeep = Color(0xFF9C5127); // bakır — küçük metin, açık tema (AA 4.97:1)
}

ThemeData buildAppTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final surface = isLight ? PanelColors.ivory : PanelColors.soot;
  final onSurface = isLight ? PanelColors.ink : PanelColors.ivoryText;
  final copper = isLight ? PanelColors.copper : PanelColors.copperBright;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: copper,
    onPrimary: PanelColors.ivoryText,
    secondary: copper,
    onSecondary: PanelColors.ivoryText,
    surface: surface,
    onSurface: onSurface,
    error: copper,
    onError: PanelColors.ivoryText,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Jost',
        fontVariations: const [FontVariation('wght', 600)],
        fontSize: 18,
        letterSpacing: 1.4,
        color: onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      // Ters blok buton — seçili süre çipinin dili; bakır zemin küçük metinde
      // AA altına düşer (3.70:1), mürekkep/fildişi 13.3:1.
      style: FilledButton.styleFrom(
        backgroundColor: isLight ? PanelColors.ink : PanelColors.ivoryText,
        foregroundColor: isLight ? PanelColors.ivoryText : PanelColors.ink,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontFamily: 'Jost', fontVariations: [
          FontVariation('wght', 500),
        ], letterSpacing: 1.2, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      // Küçük bakır metin açık temada AA için koyu keski ister (4.97:1).
      style: TextButton.styleFrom(
        foregroundColor: isLight ? PanelColors.copperDeep : PanelColors.copperBright,
        textStyle: const TextStyle(
          fontFamily: 'Jost',
          fontVariations: [FontVariation('wght', 500)],
          letterSpacing: 1.0,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PanelColors.ink,
      contentTextStyle: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 13,
        color: PanelColors.ivoryText,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Pano tipografisi + trim renkleri. Ekranlar yalnız bu uzantıyı kullanır.
extension PanelTheme on ThemeData {
  /// Trim çizgi: mürekkep %20 (açık) / fildişi %18 (koyu) — DESIGN.md 5 Sütun.
  Color get trim => colorScheme.brightness == Brightness.light
      ? PanelColors.ink.withValues(alpha: 0.2)
      : PanelColors.ivoryText.withValues(alpha: 0.18);

  /// Bakırın METİN keskisi: açık temada copperDeep (AA ≥4.5), koyuda
  /// copperBright (5.2:1). Dekoratif kontak/aksan için colorScheme.primary.
  Color get accentText => colorScheme.brightness == Brightness.light
      ? PanelColors.copperDeep
      : PanelColors.copperBright;

  /// Display: Jost, uppercase başlık/etiketler (letter-spacing ~+2%).
  TextStyle displayLabel(double size, {FontVariation wght = const FontVariation('wght', 600)}) {
    return TextStyle(
      fontFamily: 'Jost',
      fontVariations: [wght],
      fontSize: size,
      letterSpacing: size * 0.02 + 0.6,
      color: colorScheme.onSurface,
    );
  }

  /// Mono: IBM Plex Mono — hostname, süre, durum bandı (rakam/etiket kuralı).
  TextStyle mono(double size, {FontWeight? weight, Color? color}) {
    return TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: size,
      fontWeight: weight,
      color: color ?? colorScheme.onSurface,
    );
  }
}
