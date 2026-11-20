import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// Pastille de mode (« ⊕ Auto ») : 34 dp de haut, coins en feuille 17/6, fond vert pâle,
/// volant réduit (69 %) puis libellé Nunito ExtraBold 14 vert. Mesurée sur le design v2 (écran Arrosage).
class SfModePill extends StatelessWidget {
  const SfModePill({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  static const double hauteur = 34;
  static const double _echelleIcone = 0.692; // le volant de la pastille fait 69 % de celui de l'en-tête

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mode $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: hauteur,
          decoration: BoxDecoration(color: SfColors.vertPale, borderRadius: SfRadius.feuille(17, 6)),
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 14.7),
            // Icône : boîte de 16,6 dp à 8,6 dp du haut.
            Padding(
              padding: const EdgeInsets.only(top: 8.6),
              child: SfIcon(SfIcons.volant, color: SfColors.vertAuto, scale: _echelleIcone),
            ),
            const SizedBox(width: 7.1),
            // Libellé : ligne de base à 21 dp du haut.
            Baseline(
              baseline: 21,
              baselineType: TextBaseline.alphabetic,
              child: Text(label, style: SfText.etiquetteMode, maxLines: 1, softWrap: false),
            ),
            const SizedBox(width: 14),
          ]),
        ),
      ),
    );
  }
}
