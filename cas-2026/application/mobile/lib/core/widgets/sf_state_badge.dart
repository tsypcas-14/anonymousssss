import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_text.dart';

enum SfState {
  /// Rien à signaler : le badge n'est pas affiché, la ligne montre son texte simple.
  normal,

  /// « À regarder » : triangle ambre (design v2, « Un peu sec », « Bientôt bas »).
  warning,

  /// Danger : même forme, en rouge. Le design v2 ne montre pas de version « critique » en ligne ;
  /// cette variante est dérivée de la version « à regarder » (à valider).
  critical,
}

/// Badge d'état en ligne : petit triangle + texte (« ⚠ Un peu sec »).
/// Triangle de 15,75 x 13,5 dp, 7,15 dp avant le texte (Nunito SemiBold 15).
class SfStateBadge extends StatelessWidget {
  const SfStateBadge({super.key, required this.state, required this.label});

  final SfState state;
  final String label;

  /// Hauteur de la zone du badge et ligne de base du texte dans cette zone.
  static const double hauteur = 22;
  static const double ligneDeBase = 18;

  /// Le triangle est à 1,1 dp du bord gauche et 7,15 dp avant le texte.
  static const double decalageTexte = 24;

  @override
  Widget build(BuildContext context) {
    final texteStyle = switch (state) {
      SfState.critical => SfText.sousTitre.copyWith(color: SfColors.flammeTrait, fontWeight: FontWeight.w700),
      _ => SfText.sousTitre,
    };
    return Semantics(
      label: switch (state) {
        SfState.warning => 'À regarder : $label',
        SfState.critical => 'Danger : $label',
        SfState.normal => label,
      },
      excludeSemantics: true,
      child: SizedBox(
        height: hauteur,
        child: Stack(children: [
          if (state != SfState.normal)
            Positioned(
              left: 1.1,
              top: 6, // le triangle est 1,5 dp sous la ligne de base du texte
              child: SfIcon(
                SfIcons.alerte,
                color: state == SfState.critical ? SfColors.flamme : SfColors.ambre,
                ink: state == SfState.critical ? SfColors.kraft : null,
              ),
            ),
          // Enfant non positionné : c'est lui qui donne sa largeur au badge.
          Padding(
            padding: EdgeInsets.only(left: state == SfState.normal ? 0 : decalageTexte),
            child: Baseline(
              baseline: ligneDeBase,
              baselineType: TextBaseline.alphabetic,
              child: Text(label, style: texteStyle, maxLines: 1, softWrap: false),
            ),
          ),
        ]),
      ),
    );
  }
}
