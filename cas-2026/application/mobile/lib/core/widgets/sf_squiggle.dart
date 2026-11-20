import 'package:flutter/widgets.dart';

import '../sf_colors.dart';

/// Trait ondulé « fait main » sous le mot important d'un titre (design v2 : sous « bien. »).
/// Tracé repris du design : 72,52 x 8,1 dp, trait de 3,4 dp arrondi, vert pousse.
/// `scale` agrandit le tracé et son trait ; `width` l'étire en plus horizontalement pour s'adapter à un autre mot.
class SfSquiggle extends StatelessWidget {
  const SfSquiggle({super.key, this.scale = 1, this.width, this.trait = epaisseur, this.color = SfColors.pousse});

  final double scale;
  final double? width;

  /// Épaisseur du trait avant agrandissement : 3,4 dp sous « bien. », 3,1 dp sous « soif. ».
  final double trait;
  final Color color;

  static const double _largeurDesign = 72.52;
  static const double hauteur = 8.1;
  static const double epaisseur = 3.4;

  @override
  Widget build(BuildContext context) {
    final largeur = width ?? _largeurDesign * scale;
    return ExcludeSemantics(
      child: SizedBox(
        width: largeur + trait * scale,
        height: (hauteur + trait) * scale,
        child: CustomPaint(painter: _SquigglePainter(largeur / _largeurDesign, scale, color, trait)),
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  _SquigglePainter(this.sx, this.sy, this.color, this.trait);

  final double sx;
  final double sy;
  final Color color;
  final double trait;

  @override
  void paint(Canvas canvas, Size size) {
    final m = trait * sy / 2;
    canvas.translate(m, m);
    final base = Path()
      ..moveTo(0, 4.5)
      ..cubicTo(8.75, 0, 16.26, 7.2, 26.26, 3.6)
      ..cubicTo(36.26, 0, 46.26, 0.9, 56.26, 4.5)
      ..cubicTo(66.26, 8.1, 68.76, 2.7, 72.52, 1.8);
    // Le tracé est transformé (et non le canevas) pour que l'épaisseur du trait reste uniforme.
    final path = base.transform(Matrix4.diagonal3Values(sx, sy, 1).storage);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = trait * sy
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => old.sx != sx || old.sy != sy || old.color != color || old.trait != trait;
}
