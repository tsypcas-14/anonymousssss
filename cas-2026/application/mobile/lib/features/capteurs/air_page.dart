import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'capteurs_data.dart';
import 'capteurs_formes.dart';

/// Écran « L'air et la lumière » : la température en grand, une phrase, la courbe sur la plage verte 15 à 32 °C et
/// la lumière en mots. Reproduction de l'écran du design v2 (page 9) ; les valeurs viennent de [AirData].
class AirPage extends StatelessWidget {
  AirPage({super.key, AirData? data, this.onRetour}) : data = data ?? AirData.exemple();

  final AirData data;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // La hauteur en plus se répartit en trois : avant la courbe, avant sa légende, avant la ligne Lumière.
      final o1 = d + e / 3, o2 = d + 2 * e / 3, o3 = d + e;
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: onRetour),
        titreEcran(data.titre, d),
        texteBase(24, 155.9 + d, Text(data.temperature, style: SfText.chiffreGeant, maxLines: 1, softWrap: false)),
        // « °C » : Sora Bold 24, ligne de base commune avec le grand chiffre, 87,1 dp après son début.
        texteBase(111.1, 155.9 + d, Text('°C', style: SfText.titre24.copyWith(color: SfColors.encre), maxLines: 1, softWrap: false)),
        texteBase(24, 189.9 + d, Text(data.phrase, style: SfText.corps17.copyWith(height: 24 / 17)), largeur: 312),
        texteBase(24, 251.9 + o1, Text(data.periode, style: styleEtiquetteCapteur)),
        zoneFormes(formesCourbeAir, x: 24, y: 257.9 + o1, largeur: 312, hauteur: 100),
        texteBase(24, 380.9 + o2, Text(data.legende, style: SfText.note.copyWith(height: 20 / 14.5)), largeur: 312),
        zoneFormes(formesLumiere, x: 24, y: 433.9 + o3, largeur: 30, hauteur: 30),
        texteBase(68, 447.9 + o3, Text(data.lumiereTitre, style: SfText.titreLigne)),
        texteBase(68, 467.9 + o3, Text(data.lumiereTexte, style: SfText.sousTitre)),
      ]);
    });
  }
}
