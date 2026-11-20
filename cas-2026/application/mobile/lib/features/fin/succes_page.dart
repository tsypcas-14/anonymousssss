import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'fin_data.dart';
import 'fin_succes_formes.dart';

/// Écran « Succès » : une pousse, des gouttes, une phrase du métier. Reproduction de l'écran du design v2 (page 8) ;
/// plein écran sur fond vert pâle, sans barre du bas. « Merci » renvoie à Arrosage.
class SuccesPage extends StatelessWidget {
  SuccesPage({super.key, SuccesData? data, this.onMerci}) : data = data ?? SuccesData.exemple();

  final SuccesData data;
  final VoidCallback? onMerci;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(
      hauteurPage: 756,
      fond: SfColors.vertPale,
      contenu: (d, e) {
        // Hauteur en plus : l'image et le texte descendent de la moitié ; « Merci » reste en bas.
        final o = d + e / 2, o3 = d + e;
        return Stack(children: [
          zoneFormes(formesSucces, x: 0, y: 70 + o, largeur: 360, hauteur: 240),
          texteBase(24, 343.9 + o, Text(data.titre, style: SfText.titre30), largeur: 312),
          for (var i = 0; i < data.lignes.length; i++)
            texteBase(24, 377.9 + 25.0 * i + o, Text(data.lignes[i], style: SfText.corps17), largeur: 312),
          Positioned(
            left: 24,
            right: 24,
            top: 673.9 + o3,
            child: SfButton(label: data.bouton, variant: SfButtonVariant.foret, onPressed: onMerci ?? () {}),
          ),
        ]);
      },
    );
  }
}
