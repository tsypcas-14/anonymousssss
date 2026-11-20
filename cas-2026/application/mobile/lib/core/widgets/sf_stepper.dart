import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_text.dart';

/// État d'une étape du suivi d'une commande.
enum SfEtapeEtat {
  /// Terminée : rond vert plein avec une coche.
  fait,

  /// En cours : anneau bleu en pointillés.
  enCours,

  /// À venir : rond vide gris, titre grisé.
  aVenir,
}

/// Une étape : son titre et son détail (heure, durée…).
class SfEtape {
  const SfEtape({required this.titre, required this.detail, required this.etat});

  final String titre;
  final String detail;
  final SfEtapeEtat etat;
}

/// Suivi d'une commande en étapes séparées (« Ordre envoyé », « La serre l'a reçu », « La vanne s'ouvre… »,
/// « L'eau coule ») : « envoyé » n'est pas « exécuté ». Rond à gauche, texte à droite, trait vertical entre les ronds
/// (vert sous une étape terminée, gris sinon). Mesuré sur le design v2 (écran « Je lance l'arrosage »), 360 dp de large :
/// ronds de 28 dp centrés à 38 dp du bord, 70 dp entre deux étapes, texte à 66 dp.
class SfStepper extends StatelessWidget {
  const SfStepper({super.key, required this.etapes, this.pas = pasDesign});

  final List<SfEtape> etapes;

  /// Distance entre deux ronds : 70 dp dans le design ; elle peut grandir sur un écran plus haut.
  final double pas;

  static const double largeur = 360;
  static const double pasDesign = 70;

  /// Hauteur du suivi pour `n` étapes (la dernière finit 45 dp sous le haut de son rond).
  static double hauteurPour(int n, [double pas = pasDesign]) => (n - 1) * pas + 45;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: SizedBox(
        width: largeur,
        height: hauteurPour(etapes.length, pas),
        child: Stack(clipBehavior: Clip.none, children: [
          // Traits d'abord (derrière les ronds) : 2 dp de large, de 24 dp sous le haut d'un rond jusqu'au rond suivant.
          for (var i = 0; i < etapes.length - 1; i++)
            Positioned(
              left: 38,
              top: i * pas + 24,
              width: 2,
              height: pas - 24,
              child: ColoredBox(color: etapes[i].etat == SfEtapeEtat.fait ? SfColors.vertCoche : SfColors.poignee),
            ),
          for (var i = 0; i < etapes.length; i++) ..._etape(i * pas, etapes[i]),
        ]),
      ),
    );
  }

  List<Widget> _etape(double haut, SfEtape e) {
    final rond = switch (e.etat) {
      SfEtapeEtat.fait => [
          Positioned(
            left: 24,
            top: haut,
            child: Container(width: 28, height: 28, decoration: const BoxDecoration(color: SfColors.vertCoche, shape: BoxShape.circle)),
          ),
          Positioned(left: 30, top: haut + 8.9, child: SfIcon(SfIcons.cocheEtape, color: Colors.white)),
        ],
      SfEtapeEtat.enCours => [
          Positioned(left: 21.7, top: haut - 2.3, child: SfIcon(SfIcons.anneau, color: SfColors.eau)),
        ],
      SfEtapeEtat.aVenir => [
          Positioned(
            left: 24,
            top: haut,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: SfColors.kraft,
                shape: BoxShape.circle,
                border: Border.all(color: SfColors.poignee, width: 3),
              ),
            ),
          ),
        ],
    };
    final titreStyle = SfText.titreLigne.copyWith(color: e.etat == SfEtapeEtat.aVenir ? SfColors.grisDoux : SfColors.encre);
    return [
      ...rond,
      // Titre : ligne de base à 18 dp sous le haut du rond ; détail : à 40 dp.
      Positioned(
        left: 66,
        top: haut,
        child: Baseline(
          baseline: 18,
          baselineType: TextBaseline.alphabetic,
          child: Text(e.titre, style: titreStyle, maxLines: 1, softWrap: false),
        ),
      ),
      Positioned(
        left: 66,
        top: haut,
        child: Baseline(
          baseline: 40,
          baselineType: TextBaseline.alphabetic,
          child: Text(e.detail, style: SfText.sousTitre, maxLines: 1, softWrap: false),
        ),
      ),
    ];
  }
}
