import 'package:flutter/widgets.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// Carte d'explication (« Pourquoi ce matin ? ») : fond vert pâle, coins en feuille 16/6, petite pousse à gauche,
/// texte Nunito 14 vert foncé dont le début est en gras. Mesurée sur le design (écran Arrosage de la première version) :
/// 328 dp de large, 78 dp pour trois lignes (interligne 19 dp).
class SfExplainCard extends StatelessWidget {
  const SfExplainCard({super.key, required this.lead, required this.body});

  /// Début de la phrase, en gras (« Pourquoi ce matin ? »).
  final String lead;

  /// Suite de la phrase (commence par une espace).
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: SfColors.vertPale, borderRadius: SfRadius.feuille(16, 6)),
      child: Stack(children: [
        // Le texte donne sa hauteur à la carte : 9,9 dp en haut, 11,1 dp en bas, 42 dp à gauche (pousse), 14 dp à droite.
        Padding(
          padding: const EdgeInsets.fromLTRB(42, 9.9, 14, 11.1),
          child: Text.rich(
            TextSpan(
              style: SfText.explication,
              children: [
                TextSpan(text: lead, style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
        Positioned(left: 15.7, top: 15, child: SfIcon(SfIcons.pousse, color: SfColors.encreVerte)),
      ]),
    );
  }
}
