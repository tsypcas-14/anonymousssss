import 'package:flutter/material.dart';

import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'fin_data.dart';
import 'fin_securite_formes.dart';

/// Écran « Sécurité » : l'état du capteur de flamme, le contact prévenu par SMS et la dernière alerte. Reproduction de
/// l'écran du design v2 (page 8) ; les valeurs viennent de [SecuriteData].
class SecuritePage extends StatelessWidget {
  SecuritePage({super.key, SecuriteData? data, this.onContact}) : data = data ?? SecuriteData.exemple();

  final SecuriteData data;

  /// La ligne « contact de la serre » (les réglages du contact viennent ensuite).
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : les deux lignes du bas descendent d'un cinquième.
      final o2 = d + e * 0.2;
      return Stack(children: [
        texteBase(28, 60.9 + d, Text(data.titre, style: SfText.titreEcran)),
        zoneFormes(formesTuileFlamme, x: 24, y: 74.9 + d, largeur: 76, hauteur: 76),
        texteBase(116, 105.9 + d, Text(data.etat, style: SfText.titre24.copyWith(height: 29 / 24)), largeur: 220),
        texteBase(24, 190.3 + d, Text(data.explication, style: SfText.corps17.copyWith(height: 24.3 / 17)), largeur: 312),
        // Contact
        zoneFormes(formesContactSecurite, x: 29, y: 279.2 + o2, largeur: 22, hauteur: 22),
        texteBase(68, 286.9 + o2, Text(data.contactTitre, style: SfText.titreLigne)),
        texteBase(68, 306.9 + o2, Text(data.contactNumero, style: SfText.sousTitre)),
        Positioned(left: 322.2 - 1.1, top: 285.5 - 1.1 + o2, child: const SfChevron()),
        Positioned(
          left: 0,
          right: 0,
          top: 270 + o2,
          height: 50,
          child: Semantics(
            button: true,
            label: data.contactTitre,
            excludeSemantics: true,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onContact),
          ),
        ),
        Positioned(left: 24, top: 321.9 + o2, width: 312, height: 1, child: const SfDashedLine()),
        // Dernière alerte
        zoneFormes(formesDerniereAlerte, x: 30.2, y: 339.3 + o2, largeur: 18, hauteur: 22),
        texteBase(68, 347.9 + o2, Text(data.derniereTitre, style: SfText.titreLigne)),
        texteBase(68, 367.9 + o2, Text(data.derniereTexte, style: SfText.sousTitre)),
      ]);
    });
  }
}
