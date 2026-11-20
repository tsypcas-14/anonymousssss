import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_icon_button.dart';
import '../../core/widgets/sf_stepper.dart';
import 'en_cours_data.dart';

/// Écran « Je lance l'arrosage » : le suivi de la commande, étape par étape, avec le bouton pour l'arrêter.
/// Reproduction de l'écran du design v2 ; les valeurs viennent de [EnCoursData].
///
/// Mise en page : dessinée pour 360 x 756 dp. Sur un écran plus grand, le haut (titre) et le suivi s'agrandissent
/// avec la largeur et l'espace libre se répartit autour du suivi ; le bouton reste collé en bas.
class EnCoursPage extends StatelessWidget {
  const EnCoursPage({super.key, required this.data, this.onRetour, this.onArreter});

  final EnCoursData data;
  final VoidCallback? onRetour;
  final VoidCallback? onArreter;

  static const double _barreEtatDesign = 34; // hauteur de la barre d'état dans les maquettes
  static const double _hautEnteteDesign = 200; // du haut de l'écran au bas du sous-titre
  static const double _boutonDepuisBas = 78.1; // bas du bouton à 18 dp de la barre du bas : 688 - 609,9
  static const double _largeurMax = 540;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: SfColors.kraft,
        child: LayoutBuilder(builder: (context, c) {
          final largeur = math.min(c.maxWidth, _largeurMax);
          final f = largeur / 360;
          final decalage = math.max(0.0, MediaQuery.paddingOf(context).top / f - _barreEtatDesign);
          final hautEntete = (_hautEnteteDesign + decalage) * f;
          final n = data.etapes.length;
          final hauteur = math.max(c.maxHeight, hautEntete + SfStepper.hauteurPour(n) * f + 16 + _boutonDepuisBas);
          // Écran plus haut que la maquette (688 dp) : les étapes s'espacent d'une partie de la hauteur en plus
          // (au plus 30 dp de plus entre deux ronds), le reste va autour du suivi.
          final extra = math.max(0.0, hauteur / f - (688 + decalage));
          final pas = SfStepper.pasDesign + math.min(30.0, extra * 0.6 / (n - 1));
          final hautSuivi = SfStepper.hauteurPour(n, pas) * f;
          final boutonTop = hauteur - _boutonDepuisBas;
          // Dans la maquette le suivi est à 20 % de l'espace libre entre le sous-titre et le bouton.
          final libre = math.max(0.0, boutonTop - hautEntete - hautSuivi);
          final suiviTop = hautEntete + libre * 0.2;
          return SingleChildScrollView(
            child: SizedBox(
              height: hauteur,
              child: Stack(children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: SizedBox(
                    width: largeur,
                    height: hautEntete,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 360, height: _hautEnteteDesign + decalage, child: _entete(decalage)),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: suiviTop,
                  child: SizedBox(
                    width: largeur,
                    height: hautSuivi,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topLeft,
                      child: SfStepper(etapes: data.etapes, pas: pas),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: boutonTop,
                  child: SfButton(label: data.arretLabel, variant: SfButtonVariant.contour, onPressed: onArreter ?? () {}),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  /// Flèche de retour, titre « Arrosage », grand titre sur deux lignes et sous-titre (repère du design, 360 dp).
  Widget _entete(double d) {
    return Stack(children: [
      // Flèche : zone tactile de 48 dp centrée sur la flèche (35,4 ; 64).
      Positioned(
        left: 11.4,
        top: 40 + d,
        child: SfIconButton(icon: SfIcons.retour, color: SfColors.foret, label: 'Retour', onTap: onRetour),
      ),
      Positioned(
        left: 64,
        top: 0,
        child: Baseline(
          baseline: 70.9 + d,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.retourLabel, style: SfText.titreEcran),
        ),
      ),
      // Grand titre : Sora Bold 30, interligne de 33 dp, 24 dp du bord ; il passe à la ligne après « Je lance ».
      Positioned(
        left: 24,
        top: 0,
        width: 270,
        child: Baseline(
          baseline: 123.9 + d,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.titre, style: SfText.titre30.copyWith(height: 33 / 30)),
        ),
      ),
      Positioned(
        left: 24,
        top: 0,
        child: Baseline(
          baseline: 189.9 + d,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.sousTitre, style: SfText.corps17, maxLines: 1, softWrap: false),
        ),
      ),
    ]);
  }
}
