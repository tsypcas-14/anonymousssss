/// Ce que montre l'écran Aération : le ventilateur, sa règle, ce qu'il a fait aujourd'hui. Pour l'instant : les valeurs
/// d'exemple du design v2 (elles viendront du contrôleur et de l'historique).
class AerationData {
  const AerationData({
    required this.titre,
    required this.mode,
    required this.etat,
    required this.regle,
    required this.debut,
    required this.plage,
    required this.fin,
    required this.bouton,
  });

  final String titre;
  final String mode; // « Auto »
  final String etat; // « Ventilateur arrêté »
  final String regle; // « Il se lance au-dessus de 32 °C »
  final String debut; // « Aujourd'hui, il a tourné de »
  final String plage; // « 11:42 à 13:05 »
  final String fin; // « . L'air était à 32,5 °C. »
  final String bouton;

  factory AerationData.exemple() => const AerationData(
        titre: 'Aération',
        mode: 'Auto',
        etat: 'Ventilateur arrêté',
        regle: 'Il se lance au-dessus de 32 °C',
        debut: "Aujourd'hui, il a tourné de ",
        plage: '11:42 à 13:05',
        fin: ". L'air était à 32,5 °C.",
        bouton: 'Aérer maintenant',
      );
}
