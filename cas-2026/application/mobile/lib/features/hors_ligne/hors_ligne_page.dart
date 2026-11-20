import 'package:flutter/material.dart';

import '../../core/sf_text.dart';
import '../../core/widgets/sf_button.dart';
import '../../core/widgets/sf_ecran_design.dart';
import 'hors_ligne_formes.dart';

/// Ce que montre l'écran « Hors ligne » : une scène, la dernière nouvelle et le rappel du SMS flamme.
class HorsLigneData {
  const HorsLigneData({
    required this.titre,
    required this.message,
    required this.derniere,
    required this.sms,
    required this.bouton,
  });

  final String titre;
  final String message;
  final String derniere;
  final String sms;
  final String bouton;

  /// Valeurs d'exemple du design v2 (elles viendront de l'heure de la dernière mesure reçue).
  factory HorsLigneData.exemple() => const HorsLigneData(
        titre: 'Je ne vois plus la serre.',
        message: "Dernières nouvelles : 14:32. Activez le partage de connexion de ce téléphone, la serre s'y accroche toute seule.",
        derniere: 'À 14:32 : sol 37 %, réservoir 41 %, air 26 °C.',
        sms: "L'alerte flamme passe quand même par SMS.",
        bouton: 'Réessayer',
      );
}

/// Écran « Hors ligne » : le téléphone ne trouve plus la serre. Rien n'est grisé à moitié : une scène, la dernière
/// nouvelle datée, et le rappel que l'alerte flamme passe par SMS. Reproduction de l'écran du design v2 (page 12).
class HorsLignePage extends StatelessWidget {
  HorsLignePage({super.key, HorsLigneData? data, this.onReessayer}) : data = data ?? HorsLigneData.exemple();

  final HorsLigneData data;

  /// « Réessayer »
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    return CapteurEcran(contenu: (d, e) {
      // Hauteur en plus : la scène et le texte descendent d'un tiers ; le rappel SMS et le bouton restent en bas.
      final o1 = d + e / 3, o3 = d + e;
      return Stack(children: [
        zoneFormes(formesHorsLigne, x: 24, y: 55.9 + o1, largeur: 312, hauteur: 170),
        texteBase(24, 275.9 + o1, Text(data.titre, style: SfText.titre30.copyWith(height: 33 / 30)), largeur: 312),
        texteBase(24, 346.3 + o1, Text(data.message, style: SfText.corps17.copyWith(height: 24.3 / 17)), largeur: 312),
        texteBase(24, 431.9 + o1, Text(data.derniere, style: SfText.note), largeur: 312),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Baseline(
            baseline: 593.9 + o3,
            baselineType: TextBaseline.alphabetic,
            child: SizedBox(width: double.infinity, child: Text(data.sms, style: SfText.note, textAlign: TextAlign.center)),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 609.9 + o3,
          child: SfButton(label: data.bouton, variant: SfButtonVariant.foret, onPressed: onReessayer ?? () {}),
        ),
      ]);
    });
  }
}
