import 'package:flutter/material.dart';

import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'fin_data.dart';
import 'fin_erreur_formes.dart';

/// Écran « Erreur » : la vanne reçoit l'ordre mais ne s'ouvre pas ; on dit quoi vérifier, sans jargon. Reproduction de
/// l'écran du design v2 (page 8) ; plein écran, sans barre du bas. « Réessayer » renvoie à Arrosage.
class ErreurPage extends StatelessWidget {
  ErreurPage({super.key, ErreurData? data, this.onReessayer, this.onAutre}) : data = data ?? ErreurData.exemple();

  final ErreurData data;
  final VoidCallback? onReessayer;

  /// « Que faire d'autre ? »
  final VoidCallback? onAutre;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(
      hauteurPage: 756,
      contenu: (d, e) {
        // Hauteur en plus : la vanne et le texte descendent d'un tiers ; le bouton et le lien restent en bas.
        final o = d + e / 3, o3 = d + e;
        return Stack(children: [
          zoneFormes(formesVanne, x: 48, y: 95 + o, largeur: 104, hauteur: 115),
          texteBase(24, 253.9 + o, Text(data.titre, style: SfText.titre30.copyWith(height: 33 / 30)), largeur: 312),
          texteBase(24, 325.9 + o, Text(data.message, style: SfText.corps17.copyWith(height: 24.3 / 17)), largeur: 312),
          Positioned(
            left: 24,
            right: 24,
            top: 623.9 + o3,
            child: SfButton(label: data.bouton, onPressed: onReessayer ?? () {}),
          ),
          // Lien : sa ligne de base tombe 94 dp sous le haut du bouton.
          Positioned(left: 0, right: 0, top: 623.9 + 66 + o3, child: SfLink(label: data.lien, onPressed: onAutre ?? () {})),
        ]);
      },
    );
  }
}
