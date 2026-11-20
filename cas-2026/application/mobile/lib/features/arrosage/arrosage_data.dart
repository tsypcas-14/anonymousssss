/// Ce que montre l'écran Arrosage. Pour l'instant : les valeurs d'exemple du design
/// (le branchement sur l'API viendra avec les données réelles).
class ArrosageData {
  const ArrosageData({
    required this.titre,
    required this.mode,
    required this.autonomie,
    required this.niveau,
    required this.pourquoiDebut,
    required this.pourquoiSuite,
    required this.vanneNom,
    required this.vanneEtat,
    required this.actionLabel,
    required this.lienLabel,
    required this.confirmTitre,
    required this.confirmNote,
    required this.durees,
    required this.dureeParDefaut,
  });

  final String titre;
  final String mode;

  /// Phrase d'autonomie du réservoir (« Eau pour 2 jours et demi »).
  final String autonomie;

  /// Niveau du réservoir (« 41 % dans le réservoir »).
  final String niveau;

  /// Explication du dernier arrosage : début en gras (« Pourquoi ce matin ? ») puis la suite de la phrase.
  final String pourquoiDebut;
  final String pourquoiSuite;

  /// Vanne d'eau : nom et état (« Fermée · dernier arrosage 07:10 »).
  final String vanneNom;
  final String vanneEtat;

  final String actionLabel;
  final String lienLabel;

  /// Carte de confirmation qui s'ouvre sur « Arroser maintenant ».
  final String confirmTitre;
  final String confirmNote;

  /// Durées proposées, en minutes, et position de celle qui est choisie d'office.
  final List<int> durees;
  final int dureeParDefaut;

  /// Écran tel que dessiné dans le design.
  factory ArrosageData.exemple() => const ArrosageData(
        titre: 'Arrosage',
        mode: 'Auto',
        autonomie: 'Eau pour 2 jours et demi',
        niveau: '41 % dans le réservoir',
        pourquoiDebut: 'Pourquoi ce matin ?',
        pourquoiSuite: ' À 07:10, le sol était à 18 %. Le seuil est à 30 %, alors la serre a arrosé 8 minutes.',
        vanneNom: "Vanne d'eau",
        vanneEtat: 'Fermée · dernier arrosage 07:10',
        actionLabel: 'Arroser maintenant',
        lienLabel: 'Voir les arrosages de la semaine',
        confirmTitre: 'Combien de temps ?',
        confirmNote: 'Vous prenez la main. Retour en auto dans 1 h.',
        durees: [5, 10, 15],
        dureeParDefaut: 1,
      );
}
