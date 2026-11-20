// Ce que montrent les écrans de détail d'un capteur. Pour l'instant : les valeurs d'exemple du design v2
// (elles viendront des mesures du capteur et de leur historique).

/// Le sol : une phrase, le pourcentage, la courbe depuis hier et ce qu'elle montre.
class SolData {
  const SolData({
    required this.intro,
    required this.mot,
    required this.valeur,
    required this.periode,
    required this.profondeur,
    required this.legende,
  });

  final String intro; // « Le sol est »
  final String mot; // « assez humide »
  final String valeur; // « 37 % »
  final String periode; // « DEPUIS HIER, 14:30 »
  final String profondeur; // « à 10 cm de profondeur »
  final String legende;

  factory SolData.exemple() => const SolData(
        intro: 'Le sol est',
        mot: 'assez humide',
        valeur: '37 %',
        periode: 'DEPUIS HIER, 14:30',
        profondeur: 'à 10 cm de profondeur',
        legende: "Le trait rouge : en dessous, la serre arrose. Elle l'a fait à 06:52.",
      );
}

/// L'air et la lumière : la température, une phrase, la courbe sur la plage 15 à 32 °C et la lumière en mots.
class AirData {
  const AirData({
    required this.titre,
    required this.temperature,
    required this.phrase,
    required this.periode,
    required this.legende,
    required this.lumiereTitre,
    required this.lumiereTexte,
  });

  final String titre;
  final String temperature; // « 26 »
  final String phrase;
  final String periode;
  final String legende;
  final String lumiereTitre;
  final String lumiereTexte;

  factory AirData.exemple() => const AirData(
        titre: "L'air et la lumière",
        temperature: '26',
        phrase: "Il a fait jusqu'à 32,5 °C ce matin. La serre a aéré.",
        periode: 'DEPUIS HIER, 14:30',
        legende: 'Le fond vert : la plage où les tomates sont bien, de 15 à 32 °C.',
        lumiereTitre: 'Lumière',
        lumiereTexte: 'Ciel voilé, assez pour la journée',
      );
}

/// Capteur muet : il ne répond plus. La dernière mesure est datée, jamais présentée comme actuelle.
class CapteurMuetData {
  const CapteurMuetData({
    required this.titre,
    required this.annonce,
    required this.derniereMesure,
    required this.heure,
    required this.conseil,
    required this.bouton,
  });

  final String titre; // « L'air et la lumière »
  final String annonce; // « Pas de nouvelles du capteur. »
  final String derniereMesure; // « 24 °C à »
  final String heure; // « 11:08 »
  final String conseil;
  final String bouton;

  factory CapteurMuetData.exemple() => const CapteurMuetData(
        titre: "L'air et la lumière",
        annonce: 'Pas de nouvelles du capteur.',
        derniereMesure: '24 °C à',
        heure: '11:08',
        conseil: "Regardez si le capteur d'air est bien branché. L'aération continue de marcher avec les autres mesures.",
        bouton: 'Que vérifier ?',
      );
}
