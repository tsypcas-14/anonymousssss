import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'capteurs_data.dart';
import 'capteurs_formes.dart';

/// Écran « Le sol » : coupe de terre avec la sonde plantée, une phrase, le pourcentage et la courbe depuis hier.
/// Reproduction de l'écran du design v2 (page 9) ; les valeurs viennent de [SolData].
class SolPage extends StatelessWidget {
  SolPage({super.key, SolData? data, this.onRetour}) : data = data ?? SolData.exemple();

  final SolData data;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Le haut (coupe de terre) absorbe la barre d'état et la hauteur en plus : tout le reste descend d'autant.
      final o = d + e;
      return Stack(children: [
        Positioned(
          left: 0,
          top: 0,
          width: 360,
          height: 210 + o,
          child: ExcludeSemantics(child: CustomPaint(painter: _CoupePainter(d))),
        ),
        zoneFormes(formesEtiquetteProfondeur, x: 22, y: 171.9 + d, largeur: 176, hauteur: 26),
        texteBase(34, 190.6 + d, Text(data.profondeur, style: SfText.enteteDate.copyWith(color: SfColors.encre))),
        flecheRetour(centreY: 58 + d, onTap: onRetour),
        texteBase(24, 239.5 + o, Text(data.intro, style: SfText.note)),
        texteBase(
          24,
          269.9 + o,
          Text.rich(
            TextSpan(style: SfText.titre30, children: [
              TextSpan(text: '${data.mot} '),
              TextSpan(text: data.valeur, style: const TextStyle(color: SfColors.terre)),
            ]),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        texteBase(24, 302.9 + o, Text(data.periode, style: styleEtiquetteCapteur)),
        zoneFormes(formesCourbeSol, x: 24, y: 308.9 + o, largeur: 312, hauteur: 92),
        texteBase(24, 424.5 + o, Text(data.legende, style: SfText.note.copyWith(height: 21 / 14.5)), largeur: 312),
      ]);
    });
  }
}

/// Coupe de terre : ciel, couches de terre, herbe, gouttes d'eau, sonde. Le dessin du design descend de [d] dp (barre
/// d'état plus haute) ; la terre du bas se prolonge jusqu'au bas de la zone.
class _CoupePainter extends CustomPainter {
  _CoupePainter(this.d);

  final double d;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFE3CC));
    canvas.save();
    canvas.translate(0, d);
    for (final f in formesCoupeSol) {
      f.dessiner(canvas);
    }
    canvas.restore();
    canvas.drawRect(Rect.fromLTRB(0, 209 + d, size.width, size.height), Paint()..color = const Color(0xFF6E3F22));
  }

  @override
  bool shouldRepaint(_CoupePainter old) => old.d != d;
}
