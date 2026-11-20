import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icon.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_ecran_design.dart';
import '../../core/widgets/sf_stamp.dart';

/// Une alerte de la liste : une icône, un titre, une phrase et, si on peut l'ouvrir, une flèche.
class AlerteLigne {
  const AlerteLigne({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.texte,
    this.ouvrable = true,
    this.onTap,
  });

  final SfIconData icone;
  final Color couleur;
  final String titre;
  final String texte;
  final bool ouvrable;
  final VoidCallback? onTap;
}

/// Ce que montre l'écran Alertes : ce qu'il y a à regarder, puis ce qui est déjà réglé aujourd'hui.
/// Valeurs d'exemple du design v2 (elles viendront de l'historique des alertes).
class AlertesData {
  const AlertesData({required this.aRegarder, required this.regle, required this.rienEnRouge});

  final List<AlerteLigne> aRegarder;
  final List<AlerteLigne> regle;
  final String rienEnRouge;

  factory AlertesData.exemple({VoidCallback? onSol, VoidCallback? onReservoir}) => AlertesData(
        aRegarder: [
          AlerteLigne(
            icone: SfIcons.reservoir,
            couleur: SfColors.eau,
            titre: 'Le réservoir est bientôt bas',
            texte: 'Eau pour 1 jour. Remplissez-le en passant. Depuis 12:10.',
            onTap: onReservoir,
          ),
          AlerteLigne(
            icone: SfIcons.sol,
            couleur: SfColors.terre,
            titre: 'Le sol est un peu sec',
            texte: "J'arrose depuis 14:30.",
            onTap: onSol,
          ),
        ],
        regle: [
          AlerteLigne(
            icone: SfIcons.aeration,
            couleur: SfColors.vertAuto,
            titre: 'Aération terminée',
            texte: "13:05 · l'air est redescendu à 27 °C",
            ouvrable: false,
          ),
        ],
        rienEnRouge: 'rien en rouge',
      );
}

/// Écran « Alertes » : « À regarder » d'abord, « déjà réglé » ensuite. Rien de rouge sauf le danger. Reproduction de
/// l'écran du design v2 (page 10).
class AlertesPage extends StatelessWidget {
  AlertesPage({super.key, AlertesData? data, this.onRetour}) : data = data ?? AlertesData.exemple();

  final AlertesData data;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : « déjà réglé » descend d'un cinquième ; le tampon reste collé en bas.
      final o2 = d + e * 0.2, o3 = d + e;
      return Stack(children: [
        flecheRetour(centreY: 64 + d, onTap: onRetour),
        titreEcran('Alertes', d),
        texteBase(24, 112.9 + d, Text('À REGARDER', style: SfText.etiquetteCaps)),
        ..._ligne(data.aRegarder[0], 142.9 + d, icone: 143.7 + d, iconeX: 30.2, chevron: 150.5 + d),
        Positioned(left: 24, top: 194.9 + d, width: 312, height: 1, child: const SfDashedLine()),
        ..._ligne(data.aRegarder[1], 221.9 + d, icone: 213.6 + d, iconeX: 28.4, chevron: 219.5 + d),
        texteBase(24, 284.9 + o2, Text("DÉJÀ RÉGLÉ AUJOURD'HUI", style: SfText.etiquetteCaps)),
        ..._ligne(data.regle[0], 316.9 + o2, icone: 307.2 + o2, iconeX: 26.9, chevron: 0),
        // « rien en rouge » : tampon penché de 3° en bas de l'écran.
        Positioned(left: 120, top: 651 + o3, child: SfStamp(label: data.rienEnRouge, larg: 118, haut: 24)),
      ]);
    });
  }

  /// Une ligne : icône à gauche, titre (Nunito Bold 18), phrase (Nunito 15, interligne 20) et flèche à droite.
  List<Widget> _ligne(AlerteLigne l, double base, {required double icone, required double iconeX, required double chevron}) {
    final haut = base - 18;
    return [
      Positioned(
        left: iconeX - l.icone.dx,
        top: icone - l.icone.dy,
        child: ExcludeSemantics(child: SfIcon(l.icone, color: l.couleur)),
      ),
      texteBase(68, base, Text(l.titre, style: SfText.titreLigne)),
      texteBase(68, base + 19, Text(l.texte, style: SfText.sousTitre.copyWith(height: 20 / 15)), largeur: 252),
      if (l.ouvrable) Positioned(left: 322.2 - 1.1, top: chevron - 1.1, child: const SfChevron()),
      if (l.onTap != null)
        Positioned(
          left: 0,
          top: haut,
          width: 360,
          height: 60,
          child: Semantics(button: true, label: l.titre, excludeSemantics: true, child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: l.onTap)),
        ),
    ];
  }
}
