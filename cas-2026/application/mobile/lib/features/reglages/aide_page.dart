import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'aide_data.dart';

/// Écran « Aide » : quatre questions du terrain ; on touche une question pour voir sa réponse (une seule ouverte à
/// la fois). Reproduction de l'écran du design v2 (page 12) ; les valeurs viennent de [AideData].
class AidePage extends StatefulWidget {
  AidePage({super.key, AideData? data, this.onRetour}) : data = data ?? AideData.exemple();

  final AideData data;
  final VoidCallback? onRetour;

  @override
  State<AidePage> createState() => _AidePageState();
}

class _AidePageState extends State<AidePage> {
  int? _ouverte = 0; // la première question est ouverte, comme dans le design

  static const double _haut = 93.9; // haut de la première ligne
  static const double _hauteurFermee = 53; // une ligne repliée, séparateur compris

  static final TextStyle _styleReponse = SfText.corps16.copyWith(color: SfColors.texteDoux, height: 24 / 16);
  static final TextStyle _styleSigne =
      SfText.titreLigne.copyWith(fontSize: 24, fontWeight: FontWeight.w800, color: SfColors.grisDoux);

  /// Nombre de lignes de la réponse à 312 dp de large (pour la hauteur de la ligne ouverte).
  int _lignes(String texte) {
    final p = TextPainter(
      text: TextSpan(text: texte, style: _styleReponse),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 312);
    return p.computeLineMetrics().length;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return CapteurEcran(contenu: (d, e) {
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: widget.onRetour),
        titreEcran(data.titre, d),
        Positioned(
          left: 0,
          right: 0,
          top: _haut + d,
          child: Column(children: [
            for (var i = 0; i < data.questions.length; i++) _ligne(i, data.questions[i]),
          ]),
        ),
      ]);
    });
  }

  Widget _ligne(int i, AideQuestion q) {
    final ouverte = _ouverte == i;
    // Réponse : première ligne de base à 32 dp sous celle de la question, interligne de 24 dp, puis 21 dp avant le trait.
    final hauteurReponse = ouverte ? 24.0 * _lignes(q.reponse) + 8 : 0.0;
    return Semantics(
      button: true,
      expanded: ouverte,
      label: q.question,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _ouverte = ouverte ? null : i),
        child: SizedBox(
          height: _hauteurFermee + hauteurReponse,
          child: Stack(children: [
            texteBase(24, 31, Text(q.question, style: SfText.titreLigne), largeur: 280),
            // Signe « – » ou « + » à droite, 3 dp sous la ligne de base de la question.
            Positioned(
              left: ouverte ? 324 : 321.6,
              top: 0,
              child: Baseline(
                baseline: 34,
                baselineType: TextBaseline.alphabetic,
                child: Text(ouverte ? '–' : '+', style: _styleSigne),
              ),
            ),
            if (ouverte) texteBase(24, 63, Text(q.reponse, style: _styleReponse), largeur: 312),
            Positioned(left: 24, right: 24, bottom: 0, height: 1, child: const SfDashedLine()),
          ]),
        ),
      ),
    );
  }
}
