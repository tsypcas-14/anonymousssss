// Ce que montrent les écrans « succès », « erreur » et « sécurité ». Pour l'instant : les valeurs d'exemple du design v2
// (elles viendront de la commande d'arrosage, de l'état du capteur de flamme et de l'historique des alertes).

/// Écran « Succès » : l'arrosage est terminé, dit avec une image et la phrase du métier.
class SuccesData {
  const SuccesData({required this.titre, required this.lignes, required this.bouton});

  final String titre;
  final List<String> lignes;
  final String bouton;

  factory SuccesData.exemple({int minutes = 7, int sol = 41}) => SuccesData(
        titre: 'Arrosage terminé.',
        lignes: ['$minutes minutes. Le sol est monté à $sol %.', 'Les tomates disent merci.'],
        bouton: 'Merci',
      );
}

/// Écran « Erreur » : la vanne reçoit l'ordre mais ne s'ouvre pas ; on dit quoi vérifier, sans jargon.
class ErreurData {
  const ErreurData({required this.titre, required this.message, required this.bouton, required this.lien});

  final String titre;
  final String message;
  final String bouton;
  final String lien;

  factory ErreurData.exemple() => const ErreurData(
        titre: "La vanne ne s'est pas ouverte.",
        message: "J'ai bien reçu votre ordre, mais l'eau ne coule pas. Regardez si le tuyau n'est pas plié.",
        bouton: 'Réessayer',
        lien: "Que faire d'autre ?",
      );
}

/// Écran « Sécurité » : l'état du capteur de flamme, le contact prévenu par SMS, la dernière alerte.
class SecuriteData {
  const SecuriteData({
    required this.titre,
    required this.etat,
    required this.explication,
    required this.contactTitre,
    required this.contactNumero,
    required this.derniereTitre,
    required this.derniereTexte,
  });

  final String titre;
  final String etat; // « Pas de flamme dans la serre. »
  final String explication;
  final String contactTitre;
  final String contactNumero;
  final String derniereTitre;
  final String derniereTexte;

  factory SecuriteData.exemple({String contact = 'Responsable', String numero = '+216 00 ••• 000'}) => SecuriteData(
        titre: 'Sécurité',
        etat: 'Pas de flamme dans la serre.',
        explication: "Si une flamme apparaît, l'alarme sonne sur place et $contact est prévenu par SMS. Même si l'appli est fermée.",
        contactTitre: '$contact, contact de la serre',
        contactNumero: numero,
        derniereTitre: 'Dernière alerte',
        derniereTexte: 'Aucune depuis 7 jours',
      );
}
