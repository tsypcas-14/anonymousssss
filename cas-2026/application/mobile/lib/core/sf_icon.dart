import 'package:flutter/widgets.dart';

import 'sf_icons.dart';

/// Dessine une icône du design v2 (tracés vectoriels extraits du design, sans dépendance).
/// L'icône occupe sa boîte d'origine (24x24 dp) ; `color` est la couleur du trait.
/// `ink` remplace la couleur explicite de certains détails (ex. point d'exclamation de l'alerte).
class SfIcon extends StatelessWidget {
  const SfIcon(this.data, {super.key, required this.color, this.ink, this.scale = 1});

  final SfIconData data;
  final Color color;
  final Color? ink;

  /// Échelle appliquée à la boîte et aux traits (1 = taille du design).
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: data.boxWidth * scale,
      height: data.boxHeight * scale,
      child: CustomPaint(painter: _SfIconPainter(data, color, ink, scale)),
    );
  }
}

class _SfIconPainter extends CustomPainter {
  _SfIconPainter(this.data, this.color, this.ink, this.scale);

  final SfIconData data;
  final Color color;
  final Color? ink;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    canvas.translate(data.dx, data.dy);
    for (final layer in data.layers) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = layer.color == null ? color : (ink ?? layer.color!);
      if (layer.fill) {
        paint.style = PaintingStyle.fill;
      } else {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      if (layer.clip != null) {
        canvas.save();
        canvas.clipPath(layer.clip!);
        canvas.drawPath(layer.path, paint);
        canvas.restore();
      } else {
        canvas.drawPath(layer.path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SfIconPainter old) => old.data != data || old.color != color || old.ink != ink || old.scale != scale;
}
