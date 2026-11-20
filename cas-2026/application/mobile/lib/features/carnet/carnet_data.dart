import '../../core/widgets/sf_timeline_entry.dart';

/// Une ligne du carnet : heure, titre, détail et, selon le cas, une note ou le lien « Pourquoi ? ».
class CarnetEntree {
  const CarnetEntree({
    required this.heure,
    required this.titre,
    required this.detail,
    this.etat = SfFriseEtat.fait,
    this.note,
    this.lienLabel,
  });

  final String heure;
  final String titre;
  final String detail;
  final SfFriseEtat etat;
  final String? note;
  final String? lienLabel;
}

/// Les entrées d'une journée sous leur intitulé (« AUJOURD'HUI », « HIER »).
class CarnetJour {
  const CarnetJour({required this.titre, required this.entrees});

  final String titre;
  final List<CarnetEntree> entrees;
}

/// Ce que montre l'écran Le carnet. Pour l'instant : les valeurs d'exemple du design v2
/// (le branchement sur l'historique de 7 jours viendra avec les données réelles).
class CarnetData {
  const CarnetData({required this.titre, required this.filtre, required this.jours, required this.tampon});

  final String titre;

  /// Filtre affiché en haut à droite (« Tout »).
  final String filtre;
  final List<CarnetJour> jours;

  /// Tampon en bas de la liste (« 7 jours gardés »).
  final String tampon;

  factory CarnetData.exemple() => const CarnetData(
        titre: 'Le carnet',
        filtre: 'Tout',
        tampon: '7 jours gardés',
        jours: [
          CarnetJour(titre: "AUJOURD'HUI", entrees: [
            CarnetEntree(heure: '13:05', titre: 'Aération arrêtée', detail: "L'air est redescendu à 27 °C."),
            CarnetEntree(
              heure: '11:42',
              titre: 'Aération lancée',
              detail: 'Il faisait 32,5 °C.',
              note: 'La limite est à 32 °C. Au-dessus, les tomates souffrent.',
            ),
            CarnetEntree(
              heure: '06:52',
              titre: 'Arrosage, 7 minutes',
              detail: 'Le sol était à 17 %.',
              lienLabel: 'Pourquoi ?',
            ),
          ]),
          CarnetJour(titre: 'HIER', entrees: [
            CarnetEntree(
              heure: '21:10',
              titre: 'Réservoir sous 50 %',
              detail: 'Je vous préviens une fois par heure au plus.',
              etat: SfFriseEtat.avertissement,
            ),
            CarnetEntree(
              heure: '18:35',
              titre: 'Vous avez pris la main',
              detail: "Aération en manuel, jusqu'à 19:35.",
              etat: SfFriseEtat.neutre,
            ),
          ]),
        ],
      );
}
