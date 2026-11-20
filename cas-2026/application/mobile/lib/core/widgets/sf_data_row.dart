import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_text.dart';
import 'sf_state_badge.dart';

/// Ligne de donnée du design v2 : icône, titre, sous-titre (ou badge d'état), valeur et flèche,
/// avec un sillon pointillé en bas. Hauteur 60 dp (dont 1 dp de sillon).
///
/// Positions mesurées sur le design (écran de 360 dp) : icône dans une case 24x24 centrée à 39 dp,
/// texte à 68 dp, valeur alignée à droite à 60 dp du bord, flèche à 322 dp.
class SfDataRow extends StatelessWidget {
  const SfDataRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.value,
    this.state = SfState.normal,
    this.onTap,
    this.showSeparator = true,
    this.muted = false,
  });

  final SfIconData icon;
  final Color iconColor;
  final String title;

  /// Texte sous le titre. Avec `state` autre que normal, il s'affiche avec le triangle d'état.
  final String subtitle;
  final String? value;
  final SfState state;
  final VoidCallback? onTap;
  final bool showSeparator;

  /// Ligne éteinte (« Santé des plantes : Bientôt »).
  final bool muted;

  static const double hauteur = 60;

  /// Une ligne avec badge d'état fait 63 dp : le bloc titre + sous-titre reste en haut, l'icône et la flèche
  /// descendent de 3 dp, la valeur de 2 dp (mesuré sur le design v2, écran « à regarder »).
  static const double hauteurAvecEtat = 63;

  @override
  Widget build(BuildContext context) {
    final titreStyle = SfText.titreLigne.copyWith(color: muted ? SfColors.texteDoux : SfColors.encre);
    final label = [title, subtitle, ?value].join(', ');
    final avecEtat = state != SfState.normal;
    final decalage = avecEtat ? hauteurAvecEtat - hauteur : 0.0;

    return Semantics(
      button: onTap != null,
      label: state == SfState.normal ? label : '$label, ${state == SfState.warning ? "à regarder" : "danger"}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: avecEtat ? hauteurAvecEtat : hauteur,
          child: Stack(children: [
            // Icône : case 24x24 dont le coin haut-gauche est à (27, 14).
            Positioned(left: 27, top: 14 + decalage, child: SfIcon(icon, color: iconColor)),
            // Titre : ligne de base à 25 dp du haut de la ligne.
            Positioned(
              left: 68,
              top: 0,
              child: Baseline(
                baseline: 25,
                baselineType: TextBaseline.alphabetic,
                child: Text(title, style: titreStyle, maxLines: 1, softWrap: false),
              ),
            ),
            // Sous-titre ou badge d'état (ligne de base à 44 dp).
            Positioned(
              left: 68,
              top: 26,
              child: SfStateBadge(state: state, label: subtitle),
            ),
            if (value != null)
              Positioned(
                right: 60,
                top: 0,
                child: Baseline(
                  baseline: 35 + (avecEtat ? 2 : 0),
                  baselineType: TextBaseline.alphabetic,
                  child: Text(value!, style: SfText.valeur, maxLines: 1, softWrap: false),
                ),
              ),
            // Flèche de fin de ligne.
            Positioned(right: 30.3, top: 21.5 + decalage, child: const SfChevron()),
            if (showSeparator)
              const Positioned(left: 24, right: 24, bottom: 0, height: 1, child: SfDashedLine()),
          ]),
        ),
      ),
    );
  }
}

/// Sillon pointillé : tirets de 3 dp, intervalle de 2 dp, 1 dp d'épaisseur (mesuré sur le design).
class SfDashedLine extends StatelessWidget {
  const SfDashedLine({super.key, this.color = SfColors.sillon});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter(color), size: const Size(double.infinity, 1));
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (double x = 0; x < size.width; x += 5) {
      final fin = (x + 3).clamp(0, size.width).toDouble();
      canvas.drawRect(Rect.fromLTRB(x, 0, fin, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}

/// Flèche « > » : 6,4 x 12,8 dp, trait de 2,2 dp arrondi, gris olive.
class SfChevron extends StatelessWidget {
  const SfChevron({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(width: 8.6, height: 15, child: CustomPaint(painter: SfChevronPainter()));
}

class SfChevronPainter extends CustomPainter {
  const SfChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SfColors.chevron
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(1.1, 1.1)
      ..lineTo(7.5, 7.5)
      ..lineTo(1.1, 13.9);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SfChevronPainter old) => false;
}
