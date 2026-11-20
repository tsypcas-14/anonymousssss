import 'package:flutter/widgets.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// Carte d'équipement (« Vanne d'eau ») : carte blanche à bordure fine (coins en feuille 20/7), icône de l'équipement,
/// nom, état en dessous, et pastille verte cochée à droite quand tout est en ordre.
/// Mesurée sur le design (écran Arrosage de la première version) : 328 x 67 dp.
class SfEquipmentCard extends StatelessWidget {
  const SfEquipmentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ok = true,
    this.onTap,
  });

  final SfIconData icon;
  final String title;
  final String subtitle;

  /// Affiche la pastille verte cochée.
  final bool ok;
  final VoidCallback? onTap;

  static const double hauteur = 67;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $subtitle${ok ? ', en ordre' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: hauteur,
          width: double.infinity,
          decoration: BoxDecoration(color: SfColors.carte, borderRadius: SfRadius.feuille(20, 7)),
          // La bordure de 1 dp est dessinée par-dessus pour que les positions se mesurent depuis le bord extérieur.
          foregroundDecoration: BoxDecoration(
            borderRadius: SfRadius.feuille(20, 7),
            border: Border.all(color: SfColors.bordureCarte, width: 1),
          ),
          child: Stack(children: [
            // Icône : à (25,5 ; 21) du coin de la carte.
            Positioned(left: 25.5, top: 21, child: SfIcon(icon, color: SfColors.eau)),
            // Nom : ligne de base à 29 dp ; état : ligne de base à 48 dp ; texte à 57 dp du bord.
            Positioned(
              left: 57,
              top: 0,
              child: Baseline(
                baseline: 29,
                baselineType: TextBaseline.alphabetic,
                child: Text(title, style: SfText.titreCarte, maxLines: 1, softWrap: false),
              ),
            ),
            Positioned(
              left: 57,
              top: 0,
              child: Baseline(
                baseline: 48,
                baselineType: TextBaseline.alphabetic,
                child: Text(subtitle, style: SfText.sousTitreCarte, maxLines: 1, softWrap: false),
              ),
            ),
            if (ok) Positioned(right: 15.9, top: 23.9, child: SfIcon(SfIcons.coche, color: SfColors.vertCoche)),
          ]),
        ),
      ),
    );
  }
}
