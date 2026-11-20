import 'package:flutter/widgets.dart';

import '../../core/sf_forme.dart';
import 'serre_formes.dart';

/// Paysage de l'en-tête de l'écran Serre : colline, serre-tunnel, olivier, soleil et rangs de culture.
/// Dessiné pour 360 dp ; la serre reste à gauche, le soleil et l'olivier à droite, collines et rangs s'étirent.
/// Le paysage est calé en bas de l'en-tête.
class SerreIllustration extends StatelessWidget {
  const SerreIllustration({super.key, required this.formes});

  /// Les formes a dessiner (paysage de l'etat « tout va bien » ou « a regarder »).
  final List<Forme> formes;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.expand(child: CustomPaint(painter: _IllustrationPainter(formes))),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.formes);

  final List<Forme> formes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final decalageY = size.height - hauteurEnteteDesign;
    final etirement = size.width / largeurDesign;
    // Le paysage est découpé par un rectangle qui va de 217,9 dp au bas de l'en-tête (design v2) : il coupe le haut
    // du grand soleil de l'état « à regarder ».
    canvas.clipRect(Rect.fromLTRB(0, 217.9 + decalageY, size.width, size.height));
    for (final f in formes) {
      canvas.save();
      canvas.translate(f.ancre == Ancre.droite ? size.width - largeurDesign : 0, decalageY);
      if (f.ancre == Ancre.etire) canvas.scale(etirement, 1);
      f.dessiner(canvas);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) => old.formes != formes;
}
