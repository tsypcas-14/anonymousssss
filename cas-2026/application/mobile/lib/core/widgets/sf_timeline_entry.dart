import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

/// État d'une entrée de la frise : couleur du rond.
enum SfFriseEtat {
  /// Action terminée normalement (vert).
  fait,

  /// À regarder (ambre).
  avertissement,

  /// Prise en main manuelle, sans jugement (gris).
  neutre,
}

/// Une entrée de la frise du carnet : l'heure à gauche, un rond sur le trait vertical, puis le titre, le détail
/// et éventuellement une note sur fond vert pâle. Positions mesurées sur le design v2 (écran Le carnet), écran de 360 dp.
///
/// La hauteur de l'entrée suit son contenu (détail sur plusieurs lignes, note) ; le trait vertical dépasse de 8 dp
/// vers le bas pour rejoindre l'entrée suivante.
class SfTimelineEntry extends StatelessWidget {
  const SfTimelineEntry({
    super.key,
    required this.heure,
    required this.titre,
    required this.detail,
    this.etat = SfFriseEtat.fait,
    this.note,
    this.lienLabel,
    this.onLien,
    this.extraBas = 0,
  });

  final String heure;
  final String titre;
  final String detail;
  final SfFriseEtat etat;

  /// Note sur fond vert pâle sous le détail (« La limite est à 32 °C… »).
  final String? note;

  /// Lien souligné à la suite du détail (« Pourquoi ? »).
  final String? lienLabel;
  final VoidCallback? onLien;

  /// Hauteur en plus sous l'entrée (dernière entrée sur un écran plus haut que la maquette) : le trait de la frise la prolonge.
  final double extraBas;

  // Positions (dp, repère de l'écran de 360 dp ; haut de l'entrée = 13,5 dp au-dessus du rond).
  static const double _baselineHeure = 25;
  static const double _baselineTitre = 24;
  static const double _baselineDetail = 45.5; // le design alterne 45 et 46 selon l'entrée
  static const double _interligneDetail = 22;
  static const double _basApresTexte = 20; // sous la dernière ligne de base
  static const double _hautNote = 57; // haut de la note, depuis le haut de l'entrée
  static const double _basApresNote = 14;

  /// Distance entre la ligne de base et le bas de la ligne, pour un style de texte.
  static double _sousLigneDeBase(TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: 'Ag', style: style), textDirection: TextDirection.ltr)..layout();
    return tp.height - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  @override
  Widget build(BuildContext context) {
    final styleTitre = SfText.puceLabel;
    final styleDetail = SfText.sousTitre.copyWith(height: _interligneDetail / 15);
    final sousTitre = _sousLigneDeBase(styleTitre);
    final sousDetail = _sousLigneDeBase(styleDetail);

    final couleurRond = switch (etat) {
      SfFriseEtat.fait => SfColors.friseFait,
      SfFriseEtat.avertissement => SfColors.ambre,
      SfFriseEtat.neutre => SfColors.friseNeutre,
    };

    final detailTexte = Text.rich(TextSpan(style: styleDetail, children: [
      TextSpan(text: detail),
      if (lienLabel != null)
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _LienSouligne(label: lienLabel!, style: styleDetail, onTap: onLien),
        ),
    ]));

    return Stack(clipBehavior: Clip.none, children: [
      // Trait vertical : 2 dp de large, à 79 dp du bord, il dépasse de 8 dp sous l'entrée.
      const Positioned(left: 79, top: 0, bottom: -8, width: 2, child: ColoredBox(color: SfColors.friseTrait)),
      // Colonne de texte : titre et détail à 104 dp du bord gauche, 24 dp de marge à droite.
      Padding(
        padding: const EdgeInsets.only(left: 104, right: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Baseline(
            baseline: _baselineTitre,
            baselineType: TextBaseline.alphabetic,
            child: Text(titre, style: styleTitre, maxLines: 1, softWrap: false),
          ),
          Baseline(
            baseline: _baselineDetail - (_baselineTitre + sousTitre),
            baselineType: TextBaseline.alphabetic,
            child: detailTexte,
          ),
          if (note == null)
            // Bas de l'entrée : 20 dp sous la dernière ligne de base (le bloc finit à `sousDetail` sous elle).
            SizedBox(height: _basApresTexte - sousDetail)
          else ...[
            // La note commence à 57 dp du haut de l'entrée.
            SizedBox(height: _hautNote - (_baselineDetail + sousDetail)),
            _Note(texte: note!),
            const SizedBox(height: _basApresNote),
          ],
          if (extraBas > 0) SizedBox(height: extraBas),
        ]),
      ),
      // Heure : Sora Bold 15, ligne de base à 25 dp du haut de l'entrée.
      Positioned(
        left: 24,
        top: 0,
        child: Baseline(
          baseline: _baselineHeure,
          baselineType: TextBaseline.alphabetic,
          child: Text(heure, style: SfText.heure, maxLines: 1, softWrap: false),
        ),
      ),
      // Rond : 18 dp de diamètre (anneau de 3 dp), à 74 dp du bord et 12 dp du haut.
      Positioned(
        left: 74,
        top: 12,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: SfColors.kraft,
            shape: BoxShape.circle,
            border: Border.all(color: couleurRond, width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Note sur fond vert pâle dans une entrée : coins en feuille 14/5, texte Nunito SemiBold 15 à 12 dp des bords.
class _Note extends StatelessWidget {
  const _Note({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 7.6, 12, 8.4),
      decoration: BoxDecoration(color: SfColors.vertPale, borderRadius: SfRadius.feuille(14, 5)),
      child: Text(texte, style: SfText.sousTitre.copyWith(height: 21 / 15)),
    );
  }
}

/// Lien souligné dans une phrase (« Pourquoi ? ») : le trait de 1 dp est à 3 dp sous la ligne de base, comme dans le design.
class _LienSouligne extends StatelessWidget {
  const _LienSouligne({required this.label, required this.style, required this.onTap});

  final String label;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tp = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr)..layout();
    final ligneDeBase = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        // L'enfant non positionné donne sa taille et sa ligne de base au lien.
        Text(label, style: style),
        Positioned(left: 0, right: 0, top: ligneDeBase + 3, height: 1, child: ColoredBox(color: style.color ?? SfColors.texteDoux)),
      ]),
    );
  }
}
