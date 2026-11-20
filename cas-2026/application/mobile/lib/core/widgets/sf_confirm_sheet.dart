import 'package:flutter/material.dart';

import '../sf_colors.dart';
import '../sf_icons.dart';
import '../sf_radius.dart';
import '../sf_text.dart';
import 'sf_button.dart';

/// Affiche la carte de confirmation qui monte du bas, avec le voile du design (encre à 54,9 %).
/// Elle s'ouvre sur le navigateur racine : le voile et la carte recouvrent toute la page, barre du bas comprise.
Future<T?> showSfConfirmSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: SfColors.voile,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: true,
    builder: builder,
  );
}

/// Carte de confirmation : poignée, titre, choix (puces), bouton d'action, note et lien « Annuler ».
/// Hauteur 300 dp, coins du haut à 30 dp. Positions mesurées sur le design (écran « Confirmer »).
class SfConfirmSheet extends StatelessWidget {
  const SfConfirmSheet({
    super.key,
    required this.title,
    required this.choices,
    required this.selectedIndex,
    required this.onChoice,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.confirmIcon,
    this.note,
    this.cancelLabel = 'Annuler',
  });

  final String title;
  final List<String> choices;
  final int selectedIndex;
  final ValueChanged<int> onChoice;
  final String confirmLabel;
  final SfIconData? confirmIcon;
  final VoidCallback onConfirm;
  final String? note;
  final String cancelLabel;
  final VoidCallback onCancel;

  static const double hauteur = 300;

  @override
  Widget build(BuildContext context) {
    final bas = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: hauteur + bas,
      decoration: const BoxDecoration(color: SfColors.kraft, borderRadius: SfRadius.feuilleDuBas),
      child: Stack(children: [
        // Poignée : 44x5 dp, à 14 dp du haut.
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: SfColors.poignee, borderRadius: BorderRadius.circular(2.5)),
            ),
          ),
        ),
        // Titre : ligne de base à 53 dp.
        Positioned(
          left: 24,
          top: 0,
          child: Baseline(
            baseline: 53,
            baselineType: TextBaseline.alphabetic,
            child: Text(title, style: SfText.titreFeuille),
          ),
        ),
        // Puces : à 73 dp, 56 dp de haut, 10 dp entre elles.
        Positioned(
          left: 24,
          right: 24,
          top: 73,
          child: Row(children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _Puce(label: choices[i], choisie: i == selectedIndex, onTap: () => onChoice(i))),
            ],
          ]),
        ),
        // Bouton d'action : à 143 dp.
        Positioned(
          left: 24,
          right: 24,
          top: 143,
          child: SfButton(label: confirmLabel, icon: confirmIcon, onPressed: onConfirm),
        ),
        if (note != null)
          Positioned(
            left: 24,
            right: 24,
            top: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Baseline(
                baseline: 232,
                baselineType: TextBaseline.alphabetic,
                child: Text(note!, style: SfText.note, textAlign: TextAlign.center),
              ),
            ),
          ),
        // Lien d'annulation : ligne de base à 270 dp.
        Positioned(
          left: 0,
          right: 0,
          top: 242, // zone tactile de 44 dp : la ligne de base du texte tombe à 28 dp du haut, soit 270 dp
          child: Center(child: SfLink(label: cancelLabel, onPressed: onCancel)),
        ),
      ]),
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({required this.label, required this.choisie, required this.onTap});

  final String label;
  final bool choisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisie,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: choisie ? SfColors.pousse : SfColors.kraftFonce,
            borderRadius: SfRadius.puce,
          ),
          child: Stack(children: [
            Align(
              alignment: Alignment.topCenter,
              // Libellé : ligne de base à 34 dp du haut de la puce.
              child: Baseline(
                baseline: 34,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  label,
                  style: SfText.puceLabel.copyWith(color: choisie ? SfColors.encre : SfColors.texteDoux),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
