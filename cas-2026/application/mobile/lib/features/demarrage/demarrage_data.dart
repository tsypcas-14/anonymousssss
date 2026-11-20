// Ce que montrent les trois écrans du premier lancement (chargement, bienvenue, connecter ma serre). Pour l'instant :
// les valeurs d'exemple du design v2 (le nom de la serre et ce qu'on y cultive viendront de la configuration).

/// Écran « Chargement » : la serre se cherche, sans barre de progression.
class ChargementData {
  const ChargementData({required this.titre, required this.sousTitre});

  final String titre;
  final String sousTitre;

  factory ChargementData.exemple() => const ChargementData(titre: 'Je cherche la serre…', sousTitre: 'Ça prend quelques secondes.');
}

/// Écran « Bienvenue » : le même paysage que l'accueil, un message et un seul bouton.
class BienvenueData {
  const BienvenueData({required this.marque, required this.titre, required this.message, required this.bouton});

  final String marque;

  /// Les trois lignes du titre (la dernière est soulignée).
  final List<String> titre;
  final String message;
  final String bouton;

  factory BienvenueData.exemple() => const BienvenueData(
        marque: 'SmartFarm',
        titre: ['Bonjour.', 'Je veille sur', 'votre serre.'],
        message: "Je vous dis si tout va bien, et je vous préviens quand il y a quelque chose à faire.",
        bouton: 'Connecter ma serre',
      );
}

/// Une étape de la connexion : validée, avec son titre et sa phrase.
class EtapeConnexion {
  const EtapeConnexion(this.titre, this.texte);

  final String titre;
  final String texte;
}

/// Écran « Connecter ma serre » : trois étapes, toutes faites ici.
class ConnecterData {
  const ConnecterData({
    required this.titre,
    required this.intro,
    required this.etapes,
    required this.noteDebut,
    required this.noteGras,
    required this.noteFin,
    required this.bouton,
  });

  final String titre;
  final String intro;
  final List<EtapeConnexion> etapes;

  /// La note, avec un mot en gras : « … ce que vous y cultivez : **tomates**. »
  final String noteDebut;
  final String noteGras;
  final String noteFin;
  final String bouton;

  factory ConnecterData.exemple() => const ConnecterData(
        titre: 'Connecter ma serre',
        intro: 'Trois petites choses, une seule fois.',
        etapes: [
          EtapeConnexion('Partage de connexion', 'Activé sur ce téléphone'),
          EtapeConnexion('La serre est allumée', 'Le voyant vert clignote'),
          EtapeConnexion('Serre trouvée', 'Elle répond, tout est bon'),
        ],
        noteDebut: 'Vous pouvez donner un nom à votre serre, et dire ce que vous y cultivez : ',
        noteGras: 'tomates',
        noteFin: '.',
        bouton: "C'est parti",
      );
}
