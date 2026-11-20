import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// Barre de navigation du bas : 4 onglets (Serre, Arrosage, Aération, Carnet).
/// 68 dp de haut, filet de 1 dp en haut, pastille verte de 60x30 (coins en feuille 16/5) derrière l'onglet actif.
class SfBottomNav extends StatelessWidget {
  const SfBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double hauteur = 68;

  static final _onglets = <(String, SfIconData)>[
    ('Serre', SfIcons.serre),
    ('Arrosage', SfIcons.arrosage),
    ('Aération', SfIcons.aeration),
    ('Carnet', SfIcons.carnet),
  ];

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.paddingOf(context).bottom; // barre de gestes Android
    return Container(
      color: SfColors.kraft,
      height: hauteur + bas,
      padding: EdgeInsets.only(bottom: bas),
      child: Stack(children: [
        const Positioned(left: 0, right: 0, top: 0, height: 1, child: ColoredBox(color: SfColors.sillon)),
        Row(children: [
          for (var i = 0; i < _onglets.length; i++)
            Expanded(child: _Onglet(label: _onglets[i].$1, icon: _onglets[i].$2, actif: i == currentIndex, onTap: () => onTap(i))),
        ]),
      ]),
    );
  }
}

class _Onglet extends StatelessWidget {
  const _Onglet({required this.label, required this.icon, required this.actif, required this.onTap});

  final String label;
  final SfIconData icon;
  final bool actif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? SfColors.foret : SfColors.texteDoux;
    return Semantics(
      button: true,
      selected: actif,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: SfBottomNav.hauteur,
          child: Stack(children: [
            // Pastille : 60x30, à 7 dp du haut (filet compris).
            Positioned(
              top: 7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(color: actif ? SfColors.pousse : null, borderRadius: SfRadius.pastille),
                ),
              ),
            ),
            // Icône : case 24x24 centrée dans la pastille (haut à 10 dp).
            Positioned(top: 10, left: 0, right: 0, child: Center(child: SfIcon(icon, color: couleur))),
            // Libellé : ligne de base à 51 dp du haut de la barre.
            Align(
              alignment: Alignment.topCenter,
              child: Baseline(
                baseline: 51,
                baselineType: TextBaseline.alphabetic,
                child: Text(label, style: SfText.etiquetteOnglet.copyWith(color: couleur), maxLines: 1, softWrap: false),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
