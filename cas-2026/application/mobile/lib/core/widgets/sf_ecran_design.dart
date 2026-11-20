import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sf_colors.dart';
import '../sf_forme.dart';
import '../sf_icons.dart';
import '../sf_text.dart';
import 'sf_icon_button.dart';

/// Cadre commun des écrans à mise en page fixe du design v2 (détail d'un capteur, Aération, Alertes) : tout est dessiné pour 360 dp de large et
/// 688 dp de haut (jusqu'à la barre du bas). Sur un écran plus grand, le contenu s'agrandit avec la largeur ; la
/// barre d'état plus haute (`decalage`) et la hauteur en plus (`extra`) sont transmises à [contenu], qui les répartit
/// pour ne laisser aucun vide.
class CapteurEcran extends StatelessWidget {
  const CapteurEcran({
    super.key,
    required this.contenu,
    this.iconesClaires = false,
    this.fond = SfColors.kraft,
    this.hauteurPage = hauteurDesign,
  });

  /// Construit le contenu (repère 360 x (688 + decalage + extra) dp).
  final Widget Function(double decalage, double extra) contenu;
  final bool iconesClaires;

  /// Couleur de fond de l'écran.
  final Color fond;

  /// Hauteur de la page dans le design : 688 dp au-dessus de la barre du bas, 756 dp pour un écran plein.
  final double hauteurPage;

  static const double barreEtatDesign = 34;
  static const double hauteurDesign = 688;
  static const double largeurMax = 540;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconesClaires ? Brightness.light : Brightness.dark,
        statusBarBrightness: iconesClaires ? Brightness.dark : Brightness.light,
      ),
      // Material : fournit le style de texte de base aux écrans plein écran (hors barre du bas, sans Scaffold).
      child: Material(
        color: fond,
        child: LayoutBuilder(builder: (context, c) {
          // Premier affichage au démarrage : la fenêtre peut avoir une taille nulle, on n'affiche rien (évite une division par 0).
          if (c.maxWidth <= 0 || c.maxHeight <= 0) return const SizedBox.shrink();
          final largeur = math.min(c.maxWidth, largeurMax);
          final f = largeur / 360;
          final decalage = math.max(0.0, MediaQuery.paddingOf(context).top / f - barreEtatDesign);
          final hauteurDp = math.max(c.maxHeight / f, hauteurPage + decalage);
          final extra = hauteurDp - hauteurPage - decalage;
          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: largeur,
                height: hauteurDp * f,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 360, height: hauteurDp, child: contenu(decalage, extra)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dessine une liste de formes du design dans une boîte de la taille donnée (les formes sont découpées par la boîte).
class FormesPainter extends CustomPainter {
  FormesPainter(this.formes);

  final List<Forme> formes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (final f in formes) {
      f.dessiner(canvas);
    }
  }

  @override
  bool shouldRepaint(FormesPainter old) => old.formes != formes;
}

/// Une zone de [largeur] x [hauteur] dp avec les formes du design, placée à (x ; y).
Widget zoneFormes(List<Forme> formes, {required double x, required double y, required double largeur, required double hauteur}) {
  return Positioned(
    left: x,
    top: y,
    width: largeur,
    height: hauteur,
    child: ExcludeSemantics(child: CustomPaint(painter: FormesPainter(formes))),
  );
}

/// Un texte dont la ligne de base tombe à [base] dp du haut ; [largeur] le fait passer à la ligne.
Widget texteBase(double x, double base, Widget texte, {double? largeur}) {
  return Positioned(
    left: x,
    top: 0,
    width: largeur,
    child: Baseline(baseline: base, baselineType: TextBaseline.alphabetic, child: texte),
  );
}

/// Flèche de retour (zone tactile de 48 dp centrée sur la flèche : 35,4 ; [centreY]).
Widget flecheRetour({required double centreY, VoidCallback? onTap}) {
  return Positioned(
    left: 11.4,
    top: centreY - 24,
    child: SfIconButton(icon: SfIcons.retour, color: SfColors.foret, label: 'Retour', onTap: onTap),
  );
}

/// Titre d'écran « L'air et la lumière » : Sora Bold 22 vert forêt, ligne de base à 70,9 dp.
Widget titreEcran(String texte, double decalage) => texteBase(64, 70.9 + decalage, Text(texte, style: SfText.titreEcran));

/// Étiquette en capitales (« DEPUIS HIER, 14:30 »).
TextStyle get styleEtiquetteCapteur => SfText.etiquetteCaps.copyWith(fontSize: 12.5, letterSpacing: 0.78);
