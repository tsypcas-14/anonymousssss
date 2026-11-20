/// Une question du terrain et sa réponse courte.
class AideQuestion {
  const AideQuestion(this.question, this.reponse);

  final String question;
  final String reponse;
}

/// Écran « Aide » : quatre questions du terrain, en réponses courtes. Pas de mode d'emploi.
/// La première réponse est celle du design v2 ; les trois autres sont des textes de départ à relire.
class AideData {
  const AideData({required this.titre, required this.questions});

  final String titre;
  final List<AideQuestion> questions;

  factory AideData.exemple() => const AideData(
        titre: 'Aide',
        questions: [
          AideQuestion(
            'Je ne vois plus la serre',
            "Activez le partage de connexion sur ce téléphone. La serre s'y accroche toute seule, comptez une minute.",
          ),
          AideQuestion(
            "La vanne ne s'ouvre pas",
            "Vérifiez que le réservoir n'est pas vide, puis réessayez « Arroser maintenant ». Si rien ne coule, la serre vous le dit ici.",
          ),
          AideQuestion(
            'Une flamme est détectée',
            "L'alarme sonne sur place et votre contact est prévenu par SMS. Vérifiez la serre avec prudence. Si le feu grandit, appelez les secours.",
          ),
          AideQuestion(
            'Le capteur ne répond plus',
            "Regardez s'il est bien branché. La serre continue avec les autres mesures et ne montre jamais une vieille valeur comme actuelle.",
          ),
        ],
      );
}
