import 'package:flutter/material.dart';

import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'demarrage_data.dart';
import 'demarrage_formes.dart';

/// Écran « Connecter ma serre » : trois étapes, toutes faites ici, et une note sur le nom de la serre. Reproduction de
/// l'écran du design v2 (page 14) ; plein écran, sans barre du bas.
class ConnecterPage extends StatelessWidget {
  ConnecterPage({super.key, ConnecterData? data, this.onRetour, this.onTermine}) : data = data ?? ConnecterData.exemple();

  final ConnecterData data;
  final VoidCallback? onRetour;

  /// « C'est parti »
  final VoidCallback? onTermine;

  /// Ligne de base du titre de chaque étape, dans le design (70 dp d'écart).
  static const List<double> _bases = [161.9, 231.9, 301.9];

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(
      hauteurPage: 756,
      contenu: (d, e) {
        // Hauteur en plus : les étapes descendent d'un sixième, la note d'un tiers ; le bouton reste en bas.
        final o1 = d + e / 6, o2 = d + e / 3, o3 = d + e;
        return Stack(children: [
          flecheRetour(centreY: 64 + d, onTap: onRetour),
          titreEcran(data.titre, d),
          texteBase(24, 110.9 + d, Text(data.intro, style: SfText.corps17), largeur: 312),
          zoneFormes(formesEtapes, x: 25.5, y: 145.4 + o1, largeur: 25, hauteur: 165),
          for (var i = 0; i < data.etapes.length; i++) ...[
            texteBase(66, _bases[i] + o1, Text(data.etapes[i].titre, style: SfText.titreLigne), largeur: 270),
            texteBase(66, _bases[i] + 22 + o1, Text(data.etapes[i].texte, style: SfText.sousTitre), largeur: 270),
          ],
          zoneFormes(formesCarteConnexion, x: 24, y: 355.9 + o2, largeur: 312, hauteur: 98),
          texteBase(
            40,
            385.9 + o2,
            Text.rich(
              TextSpan(style: SfText.corps16.copyWith(height: 23 / 16), children: [
                TextSpan(text: data.noteDebut),
                TextSpan(text: data.noteGras, style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: data.noteFin),
              ]),
            ),
            largeur: 280,
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 677.9 + o3,
            child: SfButton(label: data.bouton, variant: SfButtonVariant.foret, onPressed: onTermine ?? () {}),
          ),
        ]);
      },
    );
  }
}
