import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_confirm_sheet.dart';
import '../../core/widgets/sf_equipment_card.dart';
import '../../core/widgets/sf_explain_card.dart';
import '../../core/widgets/sf_icon_button.dart';
import '../../core/widgets/sf_segmented_control.dart';
import 'arrosage_data.dart';
import 'reservoir_illustration.dart';

/// Écran « Arrosage » : titre et cloche, choix Auto / Manuel, l'eau qu'il reste, pourquoi la serre a arrosé,
/// l'état de la vanne, puis le geste.
/// Les valeurs viennent de [ArrosageData] (exemple du design pour l'instant).
///
/// En-tête : celui de la première version du design (titre à 16 dp, cloche, sélecteur « ⊕ Auto | Manuel »).
/// Mise en page : pensée pour 360 x 756 dp. Sur un écran plus grand, le bloc réservoir + encart s'agrandit
/// avec la largeur et l'espace libre se répartit entre le sélecteur, le réservoir, les cartes et le bouton ; le bouton reste collé en bas.
class ArrosagePage extends StatefulWidget {
  ArrosagePage({super.key, ArrosageData? data, this.onAlertes, this.onModeChange, this.onArroser, this.onVoirSemaine})
      : data = data ?? ArrosageData.exemple();

  final ArrosageData data;
  final VoidCallback? onAlertes;

  /// Appelé quand l'agriculteur change de mode : `true` = Auto, `false` = Manuel.
  final ValueChanged<bool>? onModeChange;
  /// Appelé quand l'agriculteur confirme un arrosage : la durée choisie, en minutes.
  final ValueChanged<int>? onArroser;
  final VoidCallback? onVoirSemaine;

  @override
  State<ArrosagePage> createState() => _ArrosagePageState();
}

class _ArrosagePageState extends State<ArrosagePage> {
  late bool _auto = widget.data.mode == 'Auto';

  static const double _barreEtatDesign = 34; // hauteur de la barre d'état dans les maquettes
  static const double _hauteurDesign = 688; // hauteur de la page dans la maquette (avant la barre du bas)
  static const double _largeurReservoir = 312; // réservoir + titre : marges de 24 dp
  static const double _hauteurReservoir = 152; // du haut du verre à son pied
  static const Offset _origineReservoir = Offset(24, 116);
  static const double _largeurCartes = 328; // cartes : marges de 16 dp
  static const double _hauteurCartes = 78 + 10 + SfEquipmentCard.hauteur; // carte verte + écart + carte blanche
  static const double _basEntete = 135.9; // bas du sélecteur Auto / Manuel
  static const double _boutonDepuisBas = _hauteurDesign - 561.9; // 126,1 dp

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final decalage = math.max(0.0, MediaQuery.paddingOf(context).top - _barreEtatDesign);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: SfColors.kraft,
        child: LayoutBuilder(builder: (context, c) {
          final fr = ((c.maxWidth - 48) / _largeurReservoir).clamp(1.0, 1.5);
          final fc = ((c.maxWidth - 32) / _largeurCartes).clamp(1.0, 1.5);
          final hauteur = math.max(c.maxHeight, _hauteurDesign + decalage);
          final boutonTop = hauteur - _boutonDepuisBas;
          final zoneHaut = _basEntete + decalage;
          // L'espace libre entre le sélecteur et le bouton se répartit en trois : au-dessus du réservoir,
          // entre le réservoir et les cartes, sous les cartes.
          final libre = math.max(0.0, boutonTop - zoneHaut - _hauteurReservoir * fr - _hauteurCartes * fc);
          final ecart = libre / 3;
          final reservoirTop = zoneHaut + ecart;
          final cartesTop = reservoirTop + _hauteurReservoir * fr + ecart;
          return SingleChildScrollView(
            child: SizedBox(
              height: hauteur,
              child: Stack(children: [
                // Titre : Sora Bold 21 à 16 dp du bord, ligne de base à 60,9 dp.
                Positioned(
                  left: 16,
                  top: 0,
                  child: Baseline(
                    baseline: 60.9 + decalage,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(data.titre, style: SfText.titreEcran.copyWith(fontSize: 21)),
                  ),
                ),
                // Cloche : case de 24 dp à (309,95 ; 41,8), dans une zone tactile de 48 dp.
                Positioned(
                  right: 14.05,
                  top: 29.8 + decalage,
                  child: SfIconButton(icon: SfIcons.cloche, color: SfColors.foret, label: 'Alertes', onTap: widget.onAlertes),
                ),
                // Sélecteur Auto / Manuel : 328 x 52 dp à 83,9 dp du haut.
                Positioned(
                  left: 16,
                  right: 16,
                  top: 83.9 + decalage,
                  child: SfSegmentedControl(
                    labels: const ['Auto', 'Manuel'],
                    icons: [SfIcons.volant, null],
                    selectedIndex: _auto ? 0 : 1,
                    onChanged: (i) {
                      setState(() => _auto = i == 0);
                      widget.onModeChange?.call(i == 0);
                    },
                  ),
                ),
                Positioned(
                  left: 24,
                  top: reservoirTop,
                  child: SizedBox(
                    width: _largeurReservoir * fr,
                    height: _hauteurReservoir * fr,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: _largeurReservoir, height: _hauteurReservoir, child: _reservoir(data)),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: cartesTop,
                  // Hauteur libre : si le texte prend plus de lignes que dans le design, les cartes s'allongent
                  // au lieu de déborder (la hauteur du design ne sert qu'à répartir l'espace).
                  child: SizedBox(
                    width: _largeurCartes * fc,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: _largeurCartes, child: _cartes(data)),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: boutonTop,
                  child: SfButton(label: data.actionLabel, icon: SfIcons.arrosage, onPressed: _ouvrirConfirmation),
                ),
                // Lien : sa ligne de base tombe 92 dp sous le haut du bouton (zone tactile de 44 dp).
                Positioned(
                  left: 0,
                  right: 0,
                  top: boutonTop + 64,
                  child: SfLink(label: data.lienLabel, onPressed: widget.onVoirSemaine ?? () {}),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  /// Ouvre la carte « Combien de temps ? » : l'agriculteur choisit une durée puis confirme ou annule.
  Future<void> _ouvrirConfirmation() async {
    final data = widget.data;
    var choix = data.dureeParDefaut;
    final minutes = await showSfConfirmSheet<int>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setLocal) => SfConfirmSheet(
          title: data.confirmTitre,
          choices: [for (final m in data.durees) '$m min'],
          selectedIndex: choix,
          onChoice: (i) => setLocal(() => choix = i),
          confirmLabel: 'Arroser ${data.durees[choix]} minutes',
          confirmIcon: SfIcons.arrosage,
          note: data.confirmNote,
          onConfirm: () => Navigator.of(sheet).pop(data.durees[choix]),
          onCancel: () => Navigator.of(sheet).pop(),
        ),
      ),
    );
    if (minutes != null) widget.onArroser?.call(minutes);
  }

  /// Réservoir dessiné + phrase d'autonomie, dans le repère du design : origine = (24, 116) de l'écran, 312 x 152 dp.
  Widget _reservoir(ArrosageData data) {
    return Stack(clipBehavior: Clip.none, children: [
      const Positioned.fill(child: ReservoirIllustration(origine: _origineReservoir)),
      // Titre sur 3 lignes : 24 dp, interligne 28,8 ; première ligne de base à 40,9 dp.
      Positioned(
        left: 158.9,
        top: 0,
        width: 118,
        child: Baseline(
          baseline: 40.9,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.autonomie, style: SfText.titre24),
        ),
      ),
      Positioned(
        left: 158.9,
        top: 0,
        child: Baseline(
          baseline: 127.9,
          baselineType: TextBaseline.alphabetic,
          child: Text(data.niveau, style: SfText.note, maxLines: 1, softWrap: false),
        ),
      ),
    ]);
  }

  /// Carte « Pourquoi » (78 dp) puis carte « Vanne d'eau » (67 dp), 10 dp entre elles : 328 x 155 dp.
  Widget _cartes(ArrosageData data) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SfExplainCard(lead: data.pourquoiDebut, body: data.pourquoiSuite),
      const SizedBox(height: 10),
      SfEquipmentCard(icon: SfIcons.vanne, title: data.vanneNom, subtitle: data.vanneEtat),
    ]);
  }
}
