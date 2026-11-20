import 'package:flutter/widgets.dart';

import 'reservoir_formes.dart';

/// Réservoir dessiné : verre, eau à deux vagues, ligne de réserve en tirets rouges et graduations.
/// Image du design v2 (niveau à 41 %) ; le niveau variable viendra avec les données réelles.
/// Les coordonnées sont celles de l'écran de 360 dp : `origine` est le coin haut-gauche de la zone dessinée.
class ReservoirIllustration extends StatelessWidget {
  const ReservoirIllustration({super.key, this.origine = const Offset(24, 112)});

  final Offset origine;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: SizedBox.expand(child: CustomPaint(painter: _ReservoirPainter(origine))));
  }
}

class _ReservoirPainter extends CustomPainter {
  _ReservoirPainter(this.origine);

  final Offset origine;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(-origine.dx, -origine.dy);
    for (final f in formesReservoir) {
      f.dessiner(canvas);
    }
  }

  @override
  bool shouldRepaint(_ReservoirPainter old) => old.origine != origine;
}
