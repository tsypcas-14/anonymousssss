// Ce que montrent les écrans Réglages et « Ce que la serre surveille ». Pour l'instant : les valeurs d'exemple du
// design v2 (elles viendront des réglages enregistrés et de la configuration de la serre).

/// Ce dont l'agriculteur veut être prévenu.
enum Prevenir { importantes, tout }

/// Écran Réglages : de quoi être prévenu, le contact en cas de flamme, l'accès aux seuils et à l'aide.
class ReglagesData {
  const ReglagesData({
    required this.titre,
    required this.prevenirTitre,
    required this.importantes,
    required this.importantesNote,
    required this.tout,
    required this.toutNote,
    required this.flammeNote,
    required this.contactTitre,
    required this.contact,
    required this.seuilsTitre,
    required this.seuilsNote,
    required this.aideTitre,
    required this.aideNote,
    required this.version,
    required this.serre,
  });

  final String titre;
  final String prevenirTitre;
  final String importantes;
  final String importantesNote;
  final String tout;
  final String toutNote;
  final String flammeNote;
  final String contactTitre;
  final String contact; // nom du contact, ex. « Responsable »
  final String seuilsTitre;
  final String seuilsNote;
  final String aideTitre;
  final String aideNote;
  final String version;
  final String serre;

  factory ReglagesData.exemple({String contact = 'Responsable'}) => ReglagesData(
        titre: 'Réglages',
        prevenirTitre: 'ME PRÉVENIR',
        importantes: 'Les choses importantes',
        importantesNote: 'Le reste va dans le carnet.',
        tout: 'Tout',
        toutNote: 'Aussi les arrosages terminés.',
        flammeNote: "L'alerte flamme ne se coupe pas.",
        contactTitre: 'Contact en cas de flamme',
        contact: contact,
        seuilsTitre: 'Ce que la serre surveille',
        seuilsNote: 'Les seuils',
        aideTitre: 'Aide',
        aideNote: 'Si quelque chose ne va pas',
        version: 'SmartFarm 1.0',
        serre: 'Ma serre',
      );
}

/// Un seuil : la valeur et la phrase qui dit ce que la serre fait quand elle est franchie.
class Seuil {
  const Seuil(this.valeur, this.phrase);

  final String valeur;
  final String phrase;
}

/// Écran « Ce que la serre surveille » : les seuils de départ, en mots.
class SeuilsData {
  const SeuilsData({required this.titre, required this.seuils, required this.note});

  final String titre;
  final List<Seuil> seuils;
  final String note;

  factory SeuilsData.exemple() => const SeuilsData(
        titre: 'Ce que la serre surveille',
        seuils: [
          Seuil('30 %', "Sous 30 % d'humidité, la serre arrose."),
          Seuil('32 °C', 'Au-dessus de 32 °C, elle aère.'),
          Seuil('15 °C', 'En dessous de 15 °C, elle vous prévient.'),
          Seuil('15 %', "Sous 15 % d'eau dans le réservoir, alerte."),
        ],
        note: "Ce sont des valeurs de départ. On les ajustera avec l'expérience de la serre.",
      );
}
