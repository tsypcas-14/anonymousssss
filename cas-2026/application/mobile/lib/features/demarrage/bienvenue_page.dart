import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'demarrage_data.dart';
import 'demarrage_formes.dart';

/// Écran « Bienvenue » : le même paysage que l'accueil, en grand, un message et un seul bouton. Reproduction de
/// l'écran du design v2 (page 14) ; plein écran, sans barre du bas.
class BienvenuePage extends StatelessWidget {
  BienvenuePage({super.key, BienvenueData? data, this.onConnecter}) : data = data ?? BienvenueData.exemple();

  final BienvenueData data;

  /// « Connecter ma serre »
  final VoidCallback? onConnecter;

  static final TextStyle _styleMessage = SfText.corps16.copyWith(fontSize: 18, color: const Color(0xFFE4E8D4), height: 26 / 18);

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(
      hauteurPage: 756,
      fond: SfColors.foret,
      iconesClaires: true,
      contenu: (d, e) {
        // Hauteur en plus : le titre et le message descendent d'un tiers ; paysage et bouton restent en bas.
        final o = d + e / 3, o3 = d + e;
        return Stack(children: [
          zoneFormes(formesPaysageBienvenue, x: 0, y: 570 + o3, largeur: 360, hauteur: 186),
          zoneFormes(formesLogo, x: 26.8, y: 86.3 + o, largeur: 34.4, hauteur: 27.6),
          texteBase(74, 104.9 + o, Text(data.marque, style: SfText.titreEcran.copyWith(color: SfColors.kraft))),
          for (var i = 0; i < data.titre.length; i++)
            texteBase(24, 183.9 + 40.0 * i + o, Text(data.titre[i], style: SfText.hero36), largeur: 312),
          // Trait ondulé sous « serre ».
          zoneFormes(formesTraitBienvenue, x: 127.6, y: 269.8 + o, largeur: 94, hauteur: 12),
          texteBase(24, 309.9 + o, Text(data.message, style: _styleMessage), largeur: 312),
          Positioned(
            left: 24,
            right: 24,
            top: 677.9 + o3,
            child: SfButton(label: data.bouton, onPressed: onConnecter ?? () {}),
          ),
        ]);
      },
    );
  }
}
