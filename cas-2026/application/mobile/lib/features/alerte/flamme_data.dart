/// Ce que montre l'alerte flamme. Pour l'instant : les valeurs d'exemple du design v2
/// (le contact et l'heure du SMS viendront des réglages et de l'historique).
class FlammeData {
  const FlammeData({
    required this.titre,
    required this.message,
    required this.boutonLabel,
    required this.lienLabel,
  });

  final String titre;
  final String message;
  final String boutonLabel;
  final String lienLabel;

  /// Alerte telle que dessinée dans le design : `contact` a été prévenu par SMS à `heureSms`.
  factory FlammeData.exemple({String contact = 'Responsable', String heureSms = '14:31'}) => FlammeData(
        titre: 'Une flamme dans la serre.',
        message: "L'alarme sonne sur place. $contact a été prévenu par SMS à $heureSms.",
        boutonLabel: "J'ai vu, je vérifie",
        lienLabel: 'Appeler $contact',
      );
}
