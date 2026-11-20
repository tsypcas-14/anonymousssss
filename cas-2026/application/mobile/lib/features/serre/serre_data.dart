import 'package:flutter/painting.dart';

import '../../core/sf_forme.dart';
import '../../core/sf_colors.dart';
import '../../core/sf_icons.dart';
import '../../core/widgets/sf_state_badge.dart';
import 'serre_formes.dart';
import 'serre_formes_a_regarder.dart';

/// Une ligne de l'écran Serre (sol, réservoir, air et lumière, sécurité, santé des plantes).
class SerreLigne {
  SerreLigne({
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.sousTitre,
    this.valeur,
    this.etat = SfState.normal,
    this.eteinte = false,
  });

  final SfIconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  final String? valeur;
  final SfState etat;
  final bool eteinte;
}

/// Couleurs et décor de l'en-tête de l'écran Serre selon l'état : vert quand tout va bien, jaune quand il y a
/// quelque chose à regarder.
class SerrePalette {
  const SerrePalette({
    required this.fond,
    required this.texte,
    required this.formes,
    required this.traitCouleur,
    required this.traitLargeur,
    required this.traitEpaisseur,
    required this.traitX,
    required this.iconesClaires,
    this.pastilleCloche = false,
  });

  final Color fond;

  /// Couleur du texte et des icônes de l'en-tête.
  final Color texte;
  final List<Forme> formes;

  /// Trait ondulé sous le dernier mot du titre : couleur, largeur, épaisseur et position horizontale (dp).
  final Color traitCouleur;
  final double traitLargeur;
  final double traitEpaisseur;
  final double traitX;

  /// Icônes de la barre d'état de l'appareil claires (sur fond sombre) ou foncées (sur fond clair).
  final bool iconesClaires;

  /// Pastille sur la cloche : il y a une alerte non lue.
  final bool pastilleCloche;

  static final toutVaBien = SerrePalette(
    fond: SfColors.foret,
    texte: SfColors.kraft,
    formes: formesIllustration,
    traitCouleur: SfColors.pousse,
    traitLargeur: 72.52,
    traitEpaisseur: 3.4,
    traitX: 25.25,
    iconesClaires: true,
  );

  static final aRegarder = SerrePalette(
    fond: SfColors.ble,
    texte: SfColors.encre,
    formes: formesIllustrationARegarder,
    traitCouleur: SfColors.terre,
    traitLargeur: 59.9,
    traitEpaisseur: 3.1,
    traitX: 25,
    iconesClaires: false,
    pastilleCloche: true,
  );
}

/// Ce que montre l'écran Serre. Pour l'instant : les valeurs d'exemple du design v2
/// (le branchement sur l'API viendra avec les données réelles).
class SerreData {
  const SerreData({
    required this.date,
    required this.salutation,
    required this.titre,
    required this.lieu,
    required this.lignes,
    required this.pied,
    required this.palette,
  });

  final String date;
  final String salutation;
  final String titre;
  final String lieu;
  final List<SerreLigne> lignes;
  final String pied;
  final SerrePalette palette;

  /// Écran « tout va bien » tel que dessiné dans le design v2.
  factory SerreData.exemple() => SerreData(
        date: 'Samedi 14 novembre',
        salutation: 'Bon après-midi',
        titre: 'Vos tomates vont bien.',
        lieu: 'Ma serre · il y a 2 min',
        lignes: [
          SerreLigne(
            icone: SfIcons.sol,
            couleurIcone: SfColors.terre,
            titre: 'Le sol',
            sousTitre: 'Assez humide',
            valeur: '37 %',
          ),
          SerreLigne(
            icone: SfIcons.reservoir,
            couleurIcone: SfColors.eau,
            titre: 'Le réservoir',
            sousTitre: 'Eau pour 2 jours et demi',
            valeur: '41 %',
          ),
          SerreLigne(
            icone: SfIcons.air,
            couleurIcone: SfColors.ambreFonce,
            titre: "L'air et la lumière",
            sousTitre: 'Il fait 26 °C, ciel voilé',
          ),
          SerreLigne(
            icone: SfIcons.securite,
            couleurIcone: SfColors.flammeTrait,
            titre: 'Sécurité',
            sousTitre: 'Pas de flamme',
          ),
          SerreLigne(
            icone: SfIcons.plantes,
            couleurIcone: SfColors.grisDoux,
            titre: 'Santé des plantes',
            sousTitre: 'Bientôt',
            eteinte: true,
          ),
        ],
        pied: 'La serre décide seule. Rien à faire.',
        palette: SerrePalette.toutVaBien,
      );

  /// Écran « à regarder » tel que dessiné dans le design v2 : le sol est un peu sec, le réservoir bientôt bas,
  /// la serre arrose.
  factory SerreData.aRegarder() => SerreData(
        date: 'Samedi 14 novembre',
        salutation: 'Bon après-midi',
        titre: "Les tomates ont soif. J'arrose.",
        lieu: "Ma serre · j'arrose depuis 4 min",
        lignes: [
          SerreLigne(
            icone: SfIcons.sol,
            couleurIcone: SfColors.terre,
            titre: 'Le sol',
            sousTitre: 'Un peu sec',
            valeur: '27 %',
            etat: SfState.warning,
          ),
          SerreLigne(
            icone: SfIcons.reservoir,
            couleurIcone: SfColors.eau,
            titre: 'Le réservoir',
            sousTitre: 'Bientôt bas',
            valeur: '19 %',
            etat: SfState.warning,
          ),
          SerreLigne(
            icone: SfIcons.air,
            couleurIcone: SfColors.ambreFonce,
            titre: "L'air et la lumière",
            sousTitre: 'Il fait 28 °C, grand soleil',
          ),
          SerreLigne(
            icone: SfIcons.securite,
            couleurIcone: SfColors.flammeTrait,
            titre: 'Sécurité',
            sousTitre: 'Pas de flamme',
          ),
          SerreLigne(
            icone: SfIcons.plantes,
            couleurIcone: SfColors.grisDoux,
            titre: 'Santé des plantes',
            sousTitre: 'Bientôt',
            eteinte: true,
          ),
        ],
        pied: 'La serre décide seule.',
        palette: SerrePalette.aRegarder,
      );
}
