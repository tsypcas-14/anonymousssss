import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// Sélecteur à segments (« ⊕ Auto | Manuel ») : bloc beige de 52 dp (coins en feuille 18/6) contenant deux
/// segments de 44 dp (coins 14/4), à 4 dp des bords et entre eux. Le segment choisi est vert forêt
/// avec un libellé kraft ; l'autre reste sur le fond beige. Mesuré sur le design (écran Arrosage).
class SfSegmentedControl extends StatelessWidget {
  const SfSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Icône optionnelle devant le libellé de chaque segment (même longueur que `labels`).
  final List<SfIconData?>? icons;

  static const double hauteur = 52;
  static const double _hauteurSegment = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: hauteur,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: SfColors.kraftFonce, borderRadius: SfRadius.feuille(18, 6)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              label: labels[i],
              icon: icons?[i],
              choisi: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.icon, required this.choisi, required this.onTap});

  final String label;
  final SfIconData? icon;
  final bool choisi;
  final VoidCallback onTap;

  static const double _echelleIcone = 0.692; // volant réduit à 69 %, comme dans la pastille
  static const double _ecartIcone = 6.5;

  @override
  Widget build(BuildContext context) {
    final couleur = choisi ? SfColors.kraft : SfColors.texteDoux;
    final style = SfText.segment.copyWith(color: couleur);
    return Semantics(
      button: true,
      selected: choisi,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: SfSegmentedControl._hauteurSegment,
          decoration: BoxDecoration(
            color: choisi ? SfColors.foret : null,
            borderRadius: SfRadius.feuille(14, 4),
          ),
          child: LayoutBuilder(builder: (context, c) {
            final mesure = TextPainter(
              text: TextSpan(text: label, style: style),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final boiteIcone = icon != null ? 24 * _echelleIcone + _ecartIcone : 0.0;
            final gauche = (c.maxWidth - (boiteIcone + mesure.width)) / 2;
            return Stack(children: [
              if (icon != null) Positioned(left: gauche, top: 13.6, child: SfIcon(icon!, color: couleur, scale: _echelleIcone)),
              Positioned(
                left: gauche + boiteIcone,
                top: 0,
                // Libellé : ligne de base à 27 dp du haut du segment.
                child: Baseline(
                  baseline: 27,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(label, style: style, maxLines: 1, softWrap: false),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
