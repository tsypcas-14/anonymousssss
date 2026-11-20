import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'reglages_data.dart';
import 'reglages_formes.dart';

/// Écran « Ce que la serre surveille » : les seuils de départ, en mots. Reproduction de l'écran du design v2
/// (page 11) ; les valeurs viennent de [SeuilsData].
class SeuilsPage extends StatelessWidget {
  SeuilsPage({super.key, SeuilsData? data, this.onRetour}) : data = data ?? SeuilsData.exemple();

  final SeuilsData data;
  final VoidCallback? onRetour;

  /// Ligne de base de la valeur de chaque seuil, dans le design (30 dp de plus à chaque ligne, 76 dp d'écart).
  static const List<double> _bases = [148.9, 224.9, 300.9, 377.9];
  static const List<double> _traits = [176.9, 252.9, 328.9];

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : la carte descend de la moitié ; les seuils gardent leur rythme.
      final o2 = d + e * 0.5;
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: onRetour),
        titreEcran(data.titre, d),
        for (var i = 0; i < data.seuils.length; i++) ...[
          texteBase(24, _bases[i] + d, Text(data.seuils[i].valeur, style: _styleValeur)),
          texteBase(130, _bases[i] - 16 + d, Text(data.seuils[i].phrase, style: _stylePhrase), largeur: 206),
        ],
        for (final y in _traits) Positioned(left: 24, top: y + d, width: 312, height: 1, child: const SfDashedLine()),
        zoneFormes(formesCarteSeuils, x: 24, y: 419.9 + o2, largeur: 312, hauteur: 74),
        texteBase(40, 449.9 + o2, Text(data.note, style: SfText.corps16.copyWith(height: 23 / 16)), largeur: 280),
      ]);
    });
  }

  /// « 30 % », « 32 °C » : Sora Bold 30 vert forêt.
  TextStyle get _styleValeur => SfText.titre30.copyWith(color: SfColors.foret);

  /// Phrase du seuil : Nunito Bold 17, interligne 22.
  TextStyle get _stylePhrase => SfText.titreLigne.copyWith(fontSize: 17, height: 22 / 17);
}
