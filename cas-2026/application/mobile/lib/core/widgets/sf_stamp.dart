import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_text.dart';

/// Tampon « fait main » (« 7 jours gardés ») : pastille à bordure de 2 dp, légèrement penchée de 3° vers le haut,
/// texte Sora ExtraBold 13 beige foncé centré. Mesuré sur le design (écran Le carnet) : 130 x 25 dp avec la bordure.
class SfStamp extends StatelessWidget {
  const SfStamp({super.key, required this.label, this.larg = largeur, this.haut = hauteur});

  final String label;

  /// Dimensions avec la bordure (130 x 25 dp par défaut ; « rien en rouge » : plus étroit).
  final double larg;
  final double haut;

  static const double largeur = 130;
  static const double hauteur = 25;
  static const double _angle = -3 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: _angle,
        child: Container(
          width: larg,
          height: haut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SfColors.tamponBordure, width: 2),
          ),
          // Texte : ligne de base à 4,5 dp sous le centre du tampon, donc à 17 dp du haut.
          child: Stack(children: [
            Align(
              alignment: Alignment.topCenter,
              child: Baseline(
                baseline: 17 - 2, // la bordure de 2 dp est dans le tampon : repère décalé de 2 dp
                baselineType: TextBaseline.alphabetic,
                child: Text(label, style: SfText.tampon, maxLines: 1, softWrap: false),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
