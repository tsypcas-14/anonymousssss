import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icon.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'reglages_data.dart';
import 'reglages_formes.dart';

/// Écran « Réglages » : de quoi être prévenu, le contact en cas de flamme, les seuils et l'aide. Reproduction de
/// l'écran du design v2 (page 11) ; les valeurs viennent de [ReglagesData].
class ReglagesPage extends StatefulWidget {
  ReglagesPage({super.key, ReglagesData? data, this.onSeuils, this.onContact, this.onAide})
      : data = data ?? ReglagesData.exemple();

  final ReglagesData data;
  final VoidCallback? onSeuils;
  final VoidCallback? onContact;
  final VoidCallback? onAide;

  @override
  State<ReglagesPage> createState() => _ReglagesPageState();
}

class _ReglagesPageState extends State<ReglagesPage> {
  Prevenir _prevenir = Prevenir.importantes;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : les trois lignes du bas descendent d'un cinquième ; la version et la serre restent en bas.
      final o2 = d + e * 0.2, o3 = d + e;
      return Stack(children: [
        texteBase(28, 60.9 + d, Text(data.titre, style: SfText.titreEcran)),
        texteBase(24, 87.9 + d, Text(data.prevenirTitre, style: SfText.etiquetteCaps)),
        _choix(Prevenir.importantes, data.importantes, data.importantesNote, haut: 100.9 + d, base: 121.9 + d),
        _choix(Prevenir.tout, data.tout, data.toutNote, haut: 167.9 + d, base: 188.9 + d),
        // Remarque : la flamme ne se coupe pas.
        zoneFormes(formesFlammeNote, x: 29.4, y: 234 + d, largeur: 7.2, hauteur: 11.4),
        texteBase(50, 245.9 + d, Text(data.flammeNote, style: SfText.note)),
        // Lignes
        _ligne(
          base: 291.9 + o2,
          titre: data.contactTitre,
          note: data.contact,
          chevron: 290.5 + o2,
          onTap: widget.onContact,
          icone: zoneFormes(formesContact, x: 29, y: 284.2 + o2, largeur: 22, hauteur: 22),
        ),
        Positioned(left: 24, top: 325.9 + o2, width: 312, height: 1, child: const SfDashedLine()),
        _ligne(
          base: 351.9 + o2,
          titre: data.seuilsTitre,
          note: data.seuilsNote,
          chevron: 350.5 + o2,
          onTap: widget.onSeuils,
          icone: Positioned(
            left: 28.4 - SfIcons.sol.dx,
            top: 344.6 + o2 - SfIcons.sol.dy,
            child: ExcludeSemantics(child: SfIcon(SfIcons.sol, color: SfColors.terre)),
          ),
        ),
        Positioned(left: 24, top: 385.9 + o2, width: 312, height: 1, child: const SfDashedLine()),
        _ligne(
          base: 412.9 + o2,
          titre: data.aideTitre,
          note: data.aideNote,
          chevron: 410.5 + o2,
          onTap: widget.onAide,
          icone: zoneFormes(formesAide, x: 30, y: 402.1 + o2 - 0.1, largeur: 18, hauteur: 21),
          noteBase: 431.9 + o2,
        ),
        // Pied : la version à gauche, la serre à droite (alignée sur la marge de 24 dp).
        texteBase(24, 669.9 + o3, Text(data.version, style: SfText.note)),
        Positioned(
          right: 24,
          top: 0,
          child: Baseline(
            baseline: 669.9 + o3,
            baselineType: TextBaseline.alphabetic,
            child: Text(data.serre, style: SfText.note),
          ),
        ),
      ]);
    });
  }

  /// Une option « Me prévenir » : radio à gauche, titre (Nunito Bold 18) et phrase (Nunito 15).
  Widget _choix(Prevenir valeur, String titre, String note, {required double haut, required double base}) {
    final choisi = _prevenir == valeur;
    return Positioned(
      left: 0,
      right: 0,
      top: haut,
      height: 60,
      child: Semantics(
        button: true,
        selected: choisi,
        label: titre,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _prevenir = valeur),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 25.5, top: base - 13.5 - haut, child: _Radio(choisi: choisi)),
            texteBase(64, base - haut, Text(titre, style: SfText.titreLigne)),
            texteBase(64, base - haut + 21, Text(note, style: SfText.sousTitre)),
          ]),
        ),
      ),
    );
  }

  /// Une ligne qui s'ouvre : icône à gauche, titre, phrase, flèche à droite.
  Widget _ligne({
    required double base,
    required String titre,
    required String note,
    required double chevron,
    required Widget icone,
    VoidCallback? onTap,
    double? noteBase,
  }) {
    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: [
        icone,
        texteBase(68, base, Text(titre, style: SfText.titreLigne)),
        texteBase(68, noteBase ?? base + 20, Text(note, style: SfText.sousTitre)),
        Positioned(left: 322.2 - 1.1, top: chevron - 1.1, child: const SfChevron()),
        Positioned(
          left: 0,
          right: 0,
          top: base - 24,
          height: 56,
          child: Semantics(
            button: true,
            label: titre,
            excludeSemantics: true,
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onTap),
          ),
        ),
      ]),
    );
  }
}

/// Radio : un rond de 23 dp, vert forêt avec un point quand il est choisi, gris sinon.
class _Radio extends StatelessWidget {
  const _Radio({required this.choisi});

  final bool choisi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 23,
      height: 23,
      child: CustomPaint(painter: _RadioPainter(choisi)),
    );
  }
}

class _RadioPainter extends CustomPainter {
  _RadioPainter(this.choisi);

  final bool choisi;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in choisi ? formesRadioChoisi : formesRadioVide) {
      f.dessiner(canvas);
    }
    if (choisi) {
      canvas.drawCircle(const Offset(11.5, 11.5), 5.5, Paint()..color = SfColors.foret..isAntiAlias = true);
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) => old.choisi != choisi;
}
