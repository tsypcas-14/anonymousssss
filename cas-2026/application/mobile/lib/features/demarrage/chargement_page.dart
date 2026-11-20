import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/sf_ecran_design.dart';
import '../../core/sf_text.dart';
import 'demarrage_data.dart';
import 'demarrage_formes.dart';

/// Écran « Chargement » : trois pousses qui grandissent, « Je cherche la serre… » et deux barres grises. Il dit ce qui
/// se passe, sans barre de progression. Reproduction de l'écran du design v2 (page 14) ; plein écran, sans barre du bas.
///
/// [onTermine] est appelé après [duree] (la recherche de la serre n'existe pas encore : on attend un court moment).
class ChargementPage extends StatefulWidget {
  ChargementPage({super.key, ChargementData? data, this.onTermine, this.duree = const Duration(milliseconds: 3500)})
      : data = data ?? ChargementData.exemple();

  final ChargementData data;
  final VoidCallback? onTermine;
  final Duration duree;

  @override
  State<ChargementPage> createState() => _ChargementPageState();
}

class _ChargementPageState extends State<ChargementPage> {
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    if (widget.onTermine != null) _minuteur = Timer(widget.duree, widget.onTermine!);
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return CapteurEcran(
      hauteurPage: 756,
      contenu: (d, e) {
        // Le groupe est centré dans la hauteur en plus.
        final o = d + e / 2;
        return Stack(children: [
          zoneFormes(formesPousses, x: 88, y: 238 + o, largeur: 186, hauteur: 88),
          centre(377.9 + o, Text(data.titre, style: SfText.titre24)),
          centre(410.9 + o, Text(data.sousTitre, style: SfText.corps17)),
          zoneFormes(formesSquelette, x: 60, y: 448.9 + o, largeur: 240, hauteur: 40),
        ]);
      },
    );
  }
}

/// Un texte centré sur la largeur de l'écran, ligne de base à [base] dp.
Widget centre(double base, Widget texte) => Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Baseline(
        baseline: base,
        baselineType: TextBaseline.alphabetic,
        child: SizedBox(
          width: double.infinity,
          child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: texte),
        ),
      ),
    );
