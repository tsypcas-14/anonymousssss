import 'package:flutter/material.dart';

import 'sf_colors.dart';
import 'sf_text.dart';

/// Thème Flutter du design v2. Les composants SmartFarm (SfButton, SfDataRow…) portent leurs propres
/// styles mesurés ; ce thème règle le fond, la police par défaut et les widgets Material standards.
ThemeData buildSfTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SfColors.foret,
    brightness: Brightness.light,
  ).copyWith(
    primary: SfColors.foret,
    onPrimary: SfColors.kraft,
    secondary: SfColors.ble,
    onSecondary: SfColors.encre,
    tertiary: SfColors.eau,
    surface: SfColors.kraft,
    onSurface: SfColors.encre,
    error: SfColors.flamme,
    onError: Colors.white,
    outline: SfColors.sillon,
    outlineVariant: SfColors.sillon,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SfColors.kraft,
    canvasColor: SfColors.kraft,
    fontFamily: 'Nunito',
    // Pas d'effets d'ondulation : le design est sobre.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: SfColors.sillon,
    textTheme: TextTheme(
      displayLarge: SfText.chiffreGeant,
      headlineLarge: SfText.hero36,
      headlineMedium: SfText.hero33,
      headlineSmall: SfText.titre30,
      titleLarge: SfText.titreEcran,
      titleMedium: SfText.titreLigne,
      titleSmall: SfText.valeur,
      bodyLarge: SfText.corps17,
      bodyMedium: SfText.corps16,
      bodySmall: SfText.sousTitre,
      labelLarge: SfText.bouton,
      labelMedium: SfText.etiquetteOnglet,
      labelSmall: SfText.etiquetteCaps,
    ),
  );
}
