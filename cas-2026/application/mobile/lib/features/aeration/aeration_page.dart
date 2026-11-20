import 'package:flutter/material.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_radius.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_confirm_sheet.dart';
import '../../core/widgets/sf_ecran_design.dart';
import '../../core/widgets/sf_icon_button.dart';
import '../../core/widgets/sf_segmented_control.dart';
import 'aeration_data.dart';
import 'aeration_formes.dart';

/// Écran « Aération » : même logique que l'arrosage, avec un ventilateur dessiné à la place du réservoir. Reproduction
/// de l'écran du design v2 (page 10) ; les valeurs viennent de [AerationData].
class AerationPage extends StatefulWidget {
  AerationPage({super.key, AerationData? data, this.onAerer, this.onAlertes, this.onModeChange})
      : data = data ?? AerationData.exemple();

  final AerationData data;
  final VoidCallback? onAlertes;

  /// Le choix Auto / Manuel a changé (`true` = Auto).
  final ValueChanged<bool>? onModeChange;

  /// « Aérer maintenant » : appelé avec la durée choisie (en minutes) une fois confirmée.
  final ValueChanged<int>? onAerer;

  @override
  State<AerationPage> createState() => _AerationPageState();
}

class _AerationPageState extends State<AerationPage> {
  late bool _auto = widget.data.mode == 'Auto';

  // L'en-tête est celui de l'écran Arrosage (titre, cloche, sélecteur Auto / Manuel) : le reste descend de 44 dp.
  static const double _decalageCorps = 44;

  static const List<int> _durees = [10, 20, 30];
  static const int _dureeParDefaut = 1;

  /// Ouvre la carte « Combien de temps ? » : l'agriculteur choisit une durée puis confirme ou annule.
  Future<void> _ouvrirConfirmation() async {
    var choix = _dureeParDefaut;
    final minutes = await showSfConfirmSheet<int>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setLocal) => SfConfirmSheet(
          title: 'Combien de temps ?',
          choices: [for (final m in _durees) '$m min'],
          selectedIndex: choix,
          onChoice: (i) => setLocal(() => choix = i),
          confirmLabel: 'Aérer ${_durees[choix]} minutes',
          confirmIcon: SfIcons.aeration,
          note: 'Vous prenez la main. Retour en auto dans 1 h.',
          onConfirm: () => Navigator.of(sheet).pop(_durees[choix]),
          onCancel: () => Navigator.of(sheet).pop(),
        ),
      ),
    );
    if (minutes != null) widget.onAerer?.call(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : le ventilateur descend d'un quart, l'encart de la moitié ; le bouton et le lien restent en bas.
      final o1 = d + _decalageCorps + e * 0.25, o2 = d + _decalageCorps + e * 0.5, o3 = d + e;
      return Stack(children: [
        // Titre : Sora Bold 21 à 16 dp du bord, ligne de base à 60,9 dp (comme l'écran Arrosage).
        texteBase(16, 60.9 + d, Text(data.titre, style: SfText.titreEcran.copyWith(fontSize: 21))),
        Positioned(
          right: 14.05,
          top: 29.8 + d,
          child: SfIconButton(icon: SfIcons.cloche, color: SfColors.foret, label: 'Alertes', onTap: widget.onAlertes),
        ),
        // Sélecteur Auto / Manuel : 328 x 52 dp à 83,9 dp du haut.
        Positioned(
          left: 16,
          right: 16,
          top: 83.9 + d,
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
        zoneFormes(formesVentilateur, x: 40, y: 110 + o1, largeur: 100, hauteur: 110),
        texteBase(168.9, 124.9 + o1, Text(data.etat, style: SfText.titre24.copyWith(height: 29 / 24)), largeur: 167),
        texteBase(168.9, 183.9 + o1, Text(data.regle, style: SfText.note.copyWith(height: 20 / 14.5)), largeur: 167),
        Positioned(
          left: 24,
          top: 246.9 + o2,
          width: 312,
          height: 74,
          child: Container(decoration: BoxDecoration(color: SfColors.vertPale, borderRadius: SfRadius.feuille(20, 6))),
        ),
        texteBase(
          40,
          276.9 + o2,
          Text.rich(
            TextSpan(style: SfText.corps16.copyWith(height: 23 / 16), children: [
              TextSpan(text: data.debut),
              TextSpan(text: data.plage, style: const TextStyle(fontWeight: FontWeight.w800)),
              TextSpan(text: data.fin),
            ]),
          ),
          largeur: 280,
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 561.9 + o3,
          child: SfButton(label: data.bouton, icon: SfIcons.aeration, onPressed: _ouvrirConfirmation),
        ),
      ]);
    });
  }
}
