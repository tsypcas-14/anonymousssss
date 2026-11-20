import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icon.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';

enum SfButtonVariant {
  /// Bouton plein jaune blé : l'action principale (« Arroser maintenant »).
  ble,

  /// Bouton plein vert forêt : confirmation sobre (« Merci », « C'est parti »).
  foret,

  /// Bouton contour : action secondaire (« Arrêter »).
  contour,

  /// Bouton blanc à texte rouge : sur le fond rouge de l'alerte flamme (« J'ai vu, je vérifie »).
  blanc,
}

/// Bouton du design v2 : 60 dp de haut, coins en feuille (22/7), libellé Sora ExtraBold 18.
/// L'icône optionnelle est dans une case de 28 dp, à 10 dp du libellé ; l'ensemble est centré.
class SfButton extends StatelessWidget {
  const SfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SfButtonVariant.ble,
  });

  final String label;
  final VoidCallback? onPressed;
  final SfIconData? icon;
  final SfButtonVariant variant;

  static const double hauteur = 60;
  static const double _caseIcone = 28;
  static const double _ecartIcone = 10;
  static const double _ligneDeBase = 36; // ligne de base du libellé, depuis le haut du bouton

  @override
  Widget build(BuildContext context) {
    final (Color? fond, Color texte, bool contour) = switch (variant) {
      SfButtonVariant.ble => (SfColors.ble, SfColors.encre, false),
      SfButtonVariant.foret => (SfColors.foret, SfColors.kraft, false),
      SfButtonVariant.contour => (null, SfColors.foret, true),
      SfButtonVariant.blanc => (Colors.white, SfColors.flammeTrait, false),
    };
    final style = SfText.bouton.copyWith(color: texte);
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: fond ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: SfRadius.bouton,
            side: contour ? const BorderSide(color: SfColors.foret, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: SfRadius.bouton),
            onTap: onPressed,
            child: SizedBox(
              height: hauteur,
              child: LayoutBuilder(builder: (context, c) {
                final mesure = TextPainter(
                  text: TextSpan(text: label, style: style),
                  textDirection: TextDirection.ltr,
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final groupe = (icon != null ? _caseIcone + _ecartIcone : 0) + mesure.width;
                final gauche = (c.maxWidth - groupe) / 2;
                final xLibelle = gauche + (icon != null ? _caseIcone + _ecartIcone : 0);
                return Stack(children: [
                  if (icon != null)
                    Positioned(
                      left: gauche + (_caseIcone - 24) / 2,
                      top: 17.3,
                      child: SfIcon(icon!, color: texte),
                    ),
                  Positioned(
                    left: xLibelle,
                    top: 0,
                    child: Baseline(
                      baseline: _ligneDeBase,
                      baselineType: TextBaseline.alphabetic,
                      child: Text(label, style: style, maxLines: 1, softWrap: false),
                    ),
                  ),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lien souligné (« Annuler », « Voir les arrosages de la semaine », « Tout ») : par défaut Nunito ExtraBold 16 bleu eau,
/// trait de 1 dp placé 4 dp sous la ligne de base. `style` et `ecartSoulignement` s'adaptent au lien
/// (« Tout » : 14,5 dp, trait à 1 dp sous la ligne de base).
class SfLink extends StatelessWidget {
  const SfLink({super.key, required this.label, required this.onPressed, this.style, this.ecartSoulignement = 4});

  final String label;
  final VoidCallback? onPressed;
  final TextStyle? style;

  /// Distance entre la ligne de base du texte et le trait de soulignement.
  final double ecartSoulignement;

  static const double _ligneDeBase = 20;

  @override
  Widget build(BuildContext context) {
    final texte = style ?? SfText.lien;
    return Semantics(
      link: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44), // zone tactile confortable
          child: Center(
            child: IntrinsicWidth(
              child: SizedBox(
                height: 28,
                child: Stack(children: [
                  Baseline(
                    baseline: _ligneDeBase,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(label, style: texte, maxLines: 1, softWrap: false),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _ligneDeBase + ecartSoulignement,
                    height: 1,
                    child: ColoredBox(color: texte.color ?? SfColors.eau),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
