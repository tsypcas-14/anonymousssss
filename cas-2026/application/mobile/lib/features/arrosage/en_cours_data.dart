import '../../core/widgets/sf_stepper.dart';

/// Ce que montre l'écran « Je lance l'arrosage » : le suivi de la commande, étape par étape.
/// Pour l'instant : l'état dessiné dans le design v2 (la vanne est en train de s'ouvrir) ;
/// l'avancement réel viendra avec le Raspberry Pi.
class EnCoursData {
  const EnCoursData({
    required this.retourLabel,
    required this.titre,
    required this.sousTitre,
    required this.etapes,
    required this.arretLabel,
  });

  final String retourLabel;
  final String titre;
  final String sousTitre;
  final List<SfEtape> etapes;
  final String arretLabel;

  /// Arrosage manuel de `minutes` minutes, ordre envoyé à `heure` (« 14:34 »).
  factory EnCoursData.manuel({required int minutes, required String heure}) => EnCoursData(
        retourLabel: 'Arrosage',
        titre: "Je lance l'arrosage.",
        sousTitre: '$minutes minutes, à la main.',
        etapes: [
          SfEtape(titre: 'Ordre envoyé', detail: heure, etat: SfEtapeEtat.fait),
          SfEtape(titre: "La serre l'a reçu", detail: heure, etat: SfEtapeEtat.fait),
          const SfEtape(titre: "La vanne s'ouvre…", detail: 'Quelques secondes', etat: SfEtapeEtat.enCours),
          SfEtape(titre: "L'eau coule", detail: 'Pendant $minutes minutes', etat: SfEtapeEtat.aVenir),
        ],
        arretLabel: 'Arrêter',
      );

  /// Aération manuelle de `minutes` minutes, ordre envoyé à `heure` (« 14:34 »).
  factory EnCoursData.aeration({required int minutes, required String heure}) => EnCoursData(
        retourLabel: 'Aération',
        titre: "Je lance l'aération.",
        sousTitre: '$minutes minutes, à la main.',
        etapes: [
          SfEtape(titre: 'Ordre envoyé', detail: heure, etat: SfEtapeEtat.fait),
          SfEtape(titre: "La serre l'a reçu", detail: heure, etat: SfEtapeEtat.fait),
          const SfEtape(titre: 'Le ventilateur démarre…', detail: 'Quelques secondes', etat: SfEtapeEtat.enCours),
          SfEtape(titre: "L'air circule", detail: 'Pendant $minutes minutes', etat: SfEtapeEtat.aVenir),
        ],
        arretLabel: 'Arrêter',
      );
}
