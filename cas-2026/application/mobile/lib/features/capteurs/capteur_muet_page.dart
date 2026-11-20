import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'capteurs_data.dart';
import 'capteurs_formes.dart';

/// Écran « Capteur muet » : le capteur ne répond plus. La dernière mesure est datée, jamais présentée comme actuelle
/// (PDD, section 9). Reproduction de l'écran du design v2 (page 9) ; les valeurs viennent de [CapteurMuetData].
class CapteurMuetPage extends StatelessWidget {
  CapteurMuetPage({super.key, CapteurMuetData? data, this.onRetour, this.onVerifier}) : data = data ?? CapteurMuetData.exemple();

  final CapteurMuetData data;
  final VoidCallback? onRetour;

  /// « Que vérifier ? »
  final VoidCallback? onVerifier;

  /// Bas du bouton à 18 dp de la barre du bas : 688 - 609,9.
  static const double _boutonDepuisBas = 78.1;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Le message descend d'un quart de la hauteur en plus ; le bouton reste collé en bas.
      final o = d + e * 0.25;
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: onRetour),
        titreEcran(data.titre, d),
        // Un tiret : la mesure manque.
        texteBase(24, 155.9 + o, Text('–', style: SfText.chiffreGeant.copyWith(color: const Color(0xFFA79C80)))),
        texteBase(24, 198.9 + o, Text(data.annonce, style: SfText.titre24.copyWith(height: 28 / 24)), largeur: 312),
        texteBase(
          24,
          265.3 + o,
          Text.rich(
            TextSpan(style: SfText.corps17.copyWith(height: 24.3 / 17), children: [
              const TextSpan(text: 'Dernière mesure valable : '),
              TextSpan(text: '${data.derniereMesure} ${data.heure}', style: const TextStyle(fontWeight: FontWeight.w800, color: SfColors.encre)),
              const TextSpan(text: ". Je ne l'affiche pas comme si elle était d'aujourd'hui."),
            ]),
          ),
          largeur: 312,
        ),
        zoneFormes(formesCarteMuet, x: 24, y: 339.9 + o, largeur: 312, hauteur: 98),
        texteBase(40, 369.9 + o, Text(data.conseil, style: SfText.corps16.copyWith(height: 23 / 16)), largeur: 280),
        Positioned(
          left: 24,
          right: 24,
          top: 688 + d + e - _boutonDepuisBas,
          child: SfButton(label: data.bouton, onPressed: onVerifier ?? () {}),
        ),
      ]);
    });
  }
}
