import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icon_reglages.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_icon_button.dart';
import '../../core/widgets/sf_squiggle.dart';
import 'serre_data.dart';
import 'serre_formes.dart';
import 'serre_illustration.dart';

/// En-tête vert de l'écran Serre : date, cloche et volant, salutation, grand titre souligné,
/// lieu et paysage. Positions mesurées sur le design (écran de 360 dp, ligne de base depuis le haut).
class SerreHeader extends StatelessWidget {
  const SerreHeader({
    super.key,
    required this.date,
    required this.salutation,
    required this.titre,
    required this.lieu,
    required this.palette,
    this.decalageHaut = 0,
    this.extraBas = 0,
    this.onAlertes,
    this.onReglages,
  });

  final String date;
  final String salutation;
  final String titre;
  final String lieu;
  final SerrePalette palette;

  /// Hauteur en plus quand la barre d'état de l'appareil est plus haute que celle du design.
  final double decalageHaut;

  /// Hauteur en plus quand l'écran est plus haut que la maquette (360 x 756 dp) : le ciel s'agrandit,
  /// le paysage reste collé en bas et le bloc salutation + titre + lieu se place au milieu du ciel
  /// (il descend de la moitié de cette hauteur), pour répartir l'espace de part et d'autre.
  final double extraBas;
  final VoidCallback? onAlertes;
  final VoidCallback? onReglages;

  /// Le bloc salutation + titre + lieu est agrandi quand l'écran est plus large que la maquette (360 dp),
  /// proportionnellement à la largeur de texte disponible (312 dp dans la maquette) : même retours à la ligne,
  /// texte plus grand pour mieux remplir le ciel. Plafonné à 1,25.
  static double echelleTexte(double largeur) => ((largeur - 48) / 312).clamp(1.0, 1.25);

  // Centre vertical du bloc dans la maquette : l'agrandissement se fait autour de ce point.
  static const double _centreBloc = 176;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) => _construire(context, echelleTexte(c.maxWidth)));
  }

  Widget _construire(BuildContext context, double f) {
    final h = decalageHaut; // rangée du haut : date, cloche, volant
    final b = decalageHaut + extraBas / 2; // bloc salutation, titre, lieu : centré dans le ciel
    // Position verticale d'un élément du bloc : agrandie autour du centre du bloc, puis descendue de `b`.
    double y(double yDesign) => _centreBloc + (yDesign - _centreBloc) * f + b;
    return SizedBox(
      height: hauteurEnteteDesign + decalageHaut + extraBas, // le paysage reste collé en bas
      child: ColoredBox(
        color: palette.fond,
        child: Stack(children: [
          Positioned.fill(child: SerreIllustration(formes: palette.formes)),
          _ligne(left: 24, baseline: 72.9 + h, style: SfText.enteteDate.copyWith(color: palette.texte), texte: date),
          // Cloche et volant : cases de 24 dp (haut à 55,8 dp) dans des zones tactiles de 48 dp.
          Positioned(
            right: 58,
            top: 43.8 + h,
            child: SfIconButton(icon: SfIcons.cloche, color: palette.texte, label: 'Alertes', onTap: onAlertes),
          ),
          Positioned(
            right: 10,
            top: 43.8 + h,
            child: SfIconButton(icon: sfIconReglages, color: palette.texte, label: 'Réglages', onTap: onReglages),
          ),
          _ligne(left: 24, baseline: y(122.9), style: SfText.enteteSalut.copyWith(fontSize: 17 * f, color: palette.texte), texte: salutation),
          Positioned(
            left: 24,
            right: 24,
            top: 0,
            child: Baseline(
              baseline: y(161.9),
              baselineType: TextBaseline.alphabetic,
              // Interligne de 36 dp pour un corps de 33 : « bien. » tombe à 197,9 dp.
              child: Text(titre, style: SfText.hero33.copyWith(fontSize: 33 * f, letterSpacing: -0.33 * f, height: 36 / 33, color: palette.texte)),
            ),
          ),
          // Trait ondulé sous le dernier mot (« bien. »).
          Positioned(
            left: 24 + (palette.traitX - 24) * f - palette.traitEpaisseur * f / 2,
            top: y(205.83) - palette.traitEpaisseur * f / 2,
            child: SfSquiggle(scale: f, width: palette.traitLargeur * f, trait: palette.traitEpaisseur, color: palette.traitCouleur),
          ),
          // Pastille sur la cloche (alerte non lue) : rond de 12 dp au coin haut-droit de la cloche.
          if (palette.pastilleCloche)
            Positioned(
              right: 66,
              top: 51.9 + h,
              child: IgnorePointer(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: palette.fond, shape: BoxShape.circle, border: Border.all(color: SfColors.foret, width: 2)),
                ),
              ),
            ),
          _ligne(left: 24, baseline: y(229.9), style: SfText.enteteLieu.copyWith(fontSize: 14.5 * f, color: palette.texte), texte: lieu),
        ]),
      ),
    );
  }

  Widget _ligne({required double left, required double baseline, required TextStyle style, required String texte}) {
    return Positioned(
      left: left,
      top: 0,
      child: Baseline(
        baseline: baseline,
        baselineType: TextBaseline.alphabetic,
        child: Text(texte, style: style, maxLines: 1, softWrap: false),
      ),
    );
  }
}
