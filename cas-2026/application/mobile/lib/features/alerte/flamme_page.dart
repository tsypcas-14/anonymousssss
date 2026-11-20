import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_forme.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import 'flamme_data.dart';
import 'flamme_formes.dart';

/// Alerte « Flamme » : un écran rouge plein, un titre, une phrase, un bouton. Reproduction de l'écran du design v2
/// (« impossible à couper ») : aucune barre du bas, et le retour du téléphone ne la ferme pas : seul « J'ai vu,
/// je vérifie » l'acquitte.
///
/// Mise en page : dessinée pour 360 x 756 dp. Sur un écran plus grand, le haut (tuile, titre, phrase) s'agrandit avec
/// la largeur et descend un peu avec la hauteur en plus ; le bouton et le lien restent collés en bas.
class FlammePage extends StatelessWidget {
  FlammePage({super.key, FlammeData? data, this.onVu, this.onAppeler}) : data = data ?? FlammeData.exemple();

  final FlammeData data;

  /// « J'ai vu, je vérifie » : l'agriculteur a pris connaissance de l'alerte.
  final VoidCallback? onVu;
  final VoidCallback? onAppeler;

  static const double _barreEtatDesign = 34; // hauteur de la barre d'état dans les maquettes
  static const double _hauteurDesign = 756;
  static const double _hautGroupe = 380; // du haut de l'écran au bas de la phrase
  static const double _largeurMax = 540;
  static const double _boutonDepuisBas = _hauteurDesign - 621.9; // 134,1 dp
  static const Color _blanc = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Le retour du téléphone est bloqué : l'alerte ne se ferme qu'avec le bouton.
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Material(
          color: SfColors.flamme,
          child: LayoutBuilder(builder: (context, c) {
            final largeur = math.min(c.maxWidth, _largeurMax);
            final f = largeur / 360;
            final decalage = math.max(0.0, MediaQuery.paddingOf(context).top / f - _barreEtatDesign);
            final hauteur = math.max(c.maxHeight, (_hautGroupe + decalage) * f + 40 + _boutonDepuisBas);
            final boutonTop = hauteur - _boutonDepuisBas;
            // Écran plus haut que la maquette : le groupe du haut descend de 30 % de la hauteur en plus.
            final extra = math.max(0.0, hauteur - _hauteurDesign * f);
            return SingleChildScrollView(
              child: SizedBox(
                height: hauteur,
                child: Stack(children: [
                  Positioned(
                    left: 0,
                    top: extra * 0.3,
                    child: SizedBox(
                      width: largeur,
                      height: (_hautGroupe + decalage) * f,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topLeft,
                        child: SizedBox(width: 360, height: _hautGroupe + decalage, child: _groupeHaut(decalage)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: boutonTop,
                    child: SfButton(label: data.boutonLabel, variant: SfButtonVariant.blanc, onPressed: onVu ?? () {}),
                  ),
                  // Lien : sa ligne de base tombe 96 dp sous le haut du bouton ; souligné en blanc.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: boutonTop + 68,
                    child: SfLink(
                      label: data.lienLabel,
                      onPressed: onAppeler ?? () {},
                      style: SfText.lien.copyWith(color: _blanc),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Tuile blanche inclinée avec la flamme, titre sur deux lignes et phrase (repère du design, 360 dp).
  Widget _groupeHaut(double d) {
    return Stack(children: [
      Positioned.fill(
        child: ExcludeSemantics(child: CustomPaint(painter: _TuilePainter(d))),
      ),
      // Titre : Sora Bold 36 blanc, interligne 40 dp ; il passe à la ligne après « Une flamme ».
      Positioned(
        left: 24,
        top: 0,
        width: 250,
        child: Baseline(
          baseline: 245.9 + d,
          baselineType: TextBaseline.alphabetic,
          child: Semantics(
            header: true,
            liveRegion: true,
            child: Text(data.titre, style: SfText.hero36.copyWith(color: _blanc, height: 40 / 36)),
          ),
        ),
      ),
      // Phrase : Nunito SemiBold 19 blanc, interligne 28 dp.
      Positioned(
        left: 24,
        top: 0,
        width: 312,
        child: Baseline(
          baseline: 328.9 + d,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.message, style: SfText.alerte.copyWith(height: 28 / 19)),
        ),
      ),
    ]);
  }
}

class _TuilePainter extends CustomPainter {
  _TuilePainter(this.decalage);

  final double decalage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, decalage);
    for (final Forme f in formesFlamme) {
      f.dessiner(canvas);
    }
  }

  @override
  bool shouldRepaint(_TuilePainter old) => old.decalage != decalage;
}
