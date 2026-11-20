import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_stamp.dart';
import '../../core/widgets/sf_timeline_entry.dart';
import 'carnet_data.dart';

/// Écran « Le carnet » : le journal de la serre, jour par jour. Reproduction de l'écran du design v2 ;
/// les valeurs viennent de [CarnetData] (exemple du design pour l'instant).
///
/// Mise en page : dessinée pour 360 dp de large. Sur un écran plus large, tout le contenu (textes, frise, tampon)
/// est agrandi en proportion de la largeur, et la page défile si la liste dépasse l'écran.
class CarnetPage extends StatelessWidget {
  CarnetPage({super.key, CarnetData? data, this.onFiltre, this.onPourquoi}) : data = data ?? CarnetData.exemple();

  final CarnetData data;
  final VoidCallback? onFiltre;
  final VoidCallback? onPourquoi;

  static const double _largeurDesign = 360;
  static const double _largeurMax = 540; // au-delà (tablette), la page garde cette largeur
  static const double _barreEtatDesign = 34; // hauteur de la barre d'état dans les maquettes
  static const double _hautEntete = 113.9; // haut de la première entrée
  static const double _blocJour = 37; // intitulé du 2e jour : ligne de base à 27 dp, entrée suivante 10 dp plus bas

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
          final f = largeur / _largeurDesign;
          // Barre d'état plus haute que celle de la maquette : l'en-tête descend de la différence (en dp du design).
          final decalage = math.max(0.0, MediaQuery.paddingOf(context).top / f - _barreEtatDesign);
          // Écran plus haut que la maquette (688 dp de haut) : la dernière entrée s'allonge pour que le tampon
          // reste à la même distance de la barre du bas, le trait de la frise le rejoint.
          final extra = math.max(0.0, c.maxHeight / f - (688 + decalage));
          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: largeur,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: _largeurDesign, child: _contenu(decalage, extra)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _contenu(double decalage, double extra) {
    final jours = data.jours;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // En-tête : titre, filtre et intitulé du premier jour (le haut de la première entrée est à 113,9 dp).
      SizedBox(
        height: _hautEntete + decalage,
        child: Stack(children: [
          Positioned(
            left: 28,
            top: 0,
            child: Baseline(
              baseline: 60.9 + decalage,
              baselineType: TextBaseline.alphabetic,
              child: Text(data.titre, style: SfText.titreEcran),
            ),
          ),
          // « Tout » : Nunito ExtraBold 14,5, ligne de base à 57,9 dp, trait 1 dp dessous, bord droit à 28 dp.
          Positioned(
            right: 28,
            top: 29.9 + decalage,
            child: SfLink(label: data.filtre, onPressed: onFiltre ?? () {}, style: SfText.lienCourt, ecartSoulignement: 1),
          ),
          Positioned(left: 24, top: 0, child: _intitule(jours.first.titre, 103.9 + decalage)),
        ]),
      ),
      for (var j = 0; j < jours.length; j++) ...[
        if (j > 0)
          SizedBox(
            height: _blocJour,
            child: Stack(children: [Positioned(left: 24, top: 0, child: _intitule(jours[j].titre, 27))]),
          ),
        for (final e in jours[j].entrees)
          SfTimelineEntry(
            extraBas: (j == jours.length - 1 && identical(e, jours[j].entrees.last)) ? extra : 0,
            heure: e.heure,
            titre: e.titre,
            detail: e.detail,
            etat: e.etat,
            note: e.note,
            lienLabel: e.lienLabel,
            onLien: onPourquoi ?? () {},
          ),
      ],
      // Tampon : 10 dp sous la dernière entrée, bord droit à 24 dp.
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 24, 30),
        child: Align(alignment: Alignment.centerRight, child: SfStamp(label: data.tampon)),
      ),
    ]);
  }

  Widget _intitule(String texte, double baseline) => Baseline(
        baseline: baseline,
        baselineType: TextBaseline.alphabetic,
        child: Text(texte, style: SfText.etiquetteCaps, maxLines: 1, softWrap: false),
      );
}
