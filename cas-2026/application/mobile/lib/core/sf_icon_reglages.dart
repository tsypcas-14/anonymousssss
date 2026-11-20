import 'dart:math' as math;
import 'dart:ui';

import 'sf_icons.dart';

/// Icône des réglages : une roue crantée (8 dents) avec un rond au centre, dessinée dans une boîte de 24 x 24 dp,
/// trait de 2 dp à bouts arrondis comme les autres icônes. Remplace le volant sur le bouton « Réglages » de l'accueil.
final SfIconData sfIconReglages = SfIconData(24, 24, 0, 0, [
  SfLayer(_roue(), false, 2, null),
  SfLayer(Path()..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 3.4)), false, 2, null),
]);

Path _roue() {
  const centre = Offset(12, 12);
  const dents = 8;
  const rayonCreux = 7.6; // fond entre deux dents
  const rayonPointe = 10.2; // sommet d'une dent
  const demiPied = 0.30; // demi-largeur angulaire de la dent à son pied (rad)
  const demiPointe = 0.19; // demi-largeur angulaire de la dent à son sommet (rad)
  Offset pt(double rayon, double angle) => Offset(centre.dx + rayon * math.cos(angle), centre.dy + rayon * math.sin(angle));

  final chemin = Path();
  for (var i = 0; i < dents; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / dents; // première dent en haut
    final pied1 = pt(rayonCreux, a - demiPied);
    if (i == 0) {
      chemin.moveTo(pied1.dx, pied1.dy);
    } else {
      // Arc du fond jusqu'au pied de cette dent.
      chemin.arcToPoint(pied1, radius: const Radius.circular(rayonCreux));
    }
    final p1 = pt(rayonPointe, a - demiPointe);
    final p2 = pt(rayonPointe, a + demiPointe);
    chemin.lineTo(p1.dx, p1.dy);
    chemin.lineTo(p2.dx, p2.dy);
    final pied2 = pt(rayonCreux, a + demiPied);
    chemin.lineTo(pied2.dx, pied2.dy);
  }
  // Dernier arc du fond, de la dernière dent à la première.
  final debut = pt(rayonCreux, -math.pi / 2 - demiPied);
  chemin.arcToPoint(debut, radius: const Radius.circular(rayonCreux));
  chemin.close();
  return chemin;
}
