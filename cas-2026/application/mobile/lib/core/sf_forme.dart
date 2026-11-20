import 'package:flutter/widgets.dart';

/// Ancrage horizontal d'une forme quand l'écran est plus large que le design (360 dp).
enum Ancre { gauche, droite, etire }

/// Une forme vectorielle extraite d'un écran du design (remplissage ou trait), en dp.
/// `decoupe` : si présent, la forme est découpée par ce chemin (ex. l'eau dans le verre).
class Forme {
  const Forme._(this.ancre, this.chemin, this.couleur, this.remplie, this.epaisseur, this.rond, this.decoupe);

  factory Forme.remplie(Ancre a, Path p, Color c, {Path? decoupe}) => Forme._(a, p, c, true, 0, false, decoupe);

  factory Forme.trait(Ancre a, Path p, Color c, double e, bool rond, {Path? decoupe}) =>
      Forme._(a, p, c, false, e, rond, decoupe);

  final Ancre ancre;
  final Path chemin;
  final Color couleur;
  final bool remplie;
  final double epaisseur;
  final bool rond;
  final Path? decoupe;

  /// Dessine la forme telle quelle (la transformation d'ancrage est faite par l'appelant).
  void dessiner(Canvas canvas) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = couleur;
    if (remplie) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = rond ? StrokeCap.round : StrokeCap.butt
        ..strokeJoin = rond ? StrokeJoin.round : StrokeJoin.miter;
    }
    if (decoupe != null) {
      canvas.save();
      canvas.clipPath(decoupe!);
      canvas.drawPath(chemin, paint);
      canvas.restore();
    } else {
      canvas.drawPath(chemin, paint);
    }
  }
}
