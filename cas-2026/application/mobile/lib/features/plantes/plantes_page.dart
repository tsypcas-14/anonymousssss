import 'package:flutter/material.dart';

import 'dart:typed_data';

import '../../core/sf_colors.dart';
import '../../core/sf_forme.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'plantes_formes.dart';

/// Le paysage du design fait 312 dp de large ; ici il s'étend sur toute la largeur de l'écran (360 dp) : les collines et
/// les sillons s'étirent, la pousse et le soleil gardent leur forme et suivent leur position.
const double _largeurDesign = 312;
const double _etirement = 360 / _largeurDesign;

Float64List _matrice(double sx, double dx) =>
    Float64List.fromList([sx, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, dx, 0, 0, 1]);

Forme _transformer(Forme f, Float64List m) => f.remplie
    ? Forme.remplie(f.ancre, f.chemin.transform(m), f.couleur)
    : Forme.trait(f.ancre, f.chemin.transform(m), f.couleur, f.epaisseur, f.rond);

/// Formes 0 à 5 : collines et sillons (étirés) ; 6 à 8 : pousse (centrée) ; 9 : soleil.
final List<Forme> _formesPleineLargeur = [
  for (var i = 0; i < formesPlantes.length; i++)
    if (i < 6)
      _transformer(formesPlantes[i], _matrice(_etirement, 0))
    else if (i < 9)
      _transformer(formesPlantes[i], _matrice(1, 156 * (_etirement - 1)))
    else
      _transformer(formesPlantes[i], _matrice(1, 262 * (_etirement - 1))),
];

/// Ce que montre l'écran « Santé des plantes » : la place est faite, sans rien promettre.
class PlantesData {
  const PlantesData({required this.titre, required this.annonce, required this.texte, required this.note});

  final String titre;
  final String annonce;
  final String texte;
  final String note;

  factory PlantesData.exemple() => const PlantesData(
        titre: 'Santé des plantes',
        annonce: 'Bientôt, la serre regardera vos plants.',
        texte: "Une caméra repérera les maladies et vous dira ce qu'elle voit. Pas encore installée.",
        note: "Quand ce sera prêt, chaque résultat sera marqué « à confirmer ». Une photo n'est pas un diagnostic.",
      );
}

/// Écran « Santé des plantes » : une jeune pousse, une annonce et ce qui viendra. Reproduction de l'écran du design v2
/// (page 12) ; les valeurs viennent de [PlantesData].
class PlantesPage extends StatelessWidget {
  PlantesPage({super.key, PlantesData? data, this.onRetour}) : data = data ?? PlantesData.exemple();

  final PlantesData data;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : l'annonce descend d'un sixième, la carte d'un tiers.
      final o1 = d + e / 6, o2 = d + e / 3;
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: onRetour),
        titreEcran(data.titre, d),
        zoneFormes(_formesPleineLargeur, x: 0, y: 101.9 + d, largeur: 360, hauteur: 190),
        texteBase(24, 337.9 + o1, Text(data.annonce, style: SfText.titre24.copyWith(height: 28 / 24)), largeur: 312),
        texteBase(24, 402.3 + o1, Text(data.texte, style: SfText.corps17.copyWith(height: 24.3 / 17)), largeur: 312),
        zoneFormes(formesCarteCamera, x: 24, y: 476.9 + o2, largeur: 312, hauteur: 93),
        texteBase(
          40,
          505.9 + o2,
          Text(data.note, style: SfText.sousTitre.copyWith(color: SfColors.texteFort, height: 22 / 15)),
          largeur: 280,
        ),
      ]);
    });
  }
}
