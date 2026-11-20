import 'dart:ui';

/// Palette du design v2. Valeurs lues dans le PDF du design (pas estimées).
/// Les six noms de base (forêt, pousse, blé, kraft, eau, terre) sont ceux cités par le design.
abstract final class SfColors {
  // Identité
  static const foret = Color(0xFF1E4D2B); // titres actifs, fond d'en-tête, bouton sombre, contour
  static const pousse = Color(0xFFA9D35A); // onglet actif, puce choisie
  static const ble = Color(0xFFE9B949); // bouton principal
  static const kraft = Color(0xFFF6F1E4); // fond des écrans
  static const eau = Color(0xFF1F6C8A); // réservoir, liens
  static const terre = Color(0xFF8A5230); // sol

  // Textes
  static const encre = Color(0xFF14281A); // texte principal
  static const encreVerte = Color(0xFF1F3A22); // texte et pousse de la carte « Pourquoi »
  static const texteFort = Color(0xFF2C3A2C); // paragraphes
  static const texteDoux = Color(0xFF5B5646); // texte secondaire, onglets inactifs
  static const grisDoux = Color(0xFF8A8470); // éléments éteints

  // Surfaces et traits
  static const sillon = Color(0xFFD5CAAB); // séparateurs pointillés, bordure de la barre du bas
  static const kraftFonce = Color(0xFFEDE5D0); // puce non choisie
  static const poignee = Color(0xFFC9BE9F); // poignée de la feuille du bas
  static const chevron = Color(0xFF9A8F72); // flèche de fin de ligne
  static const carte = Color(0xFFFFFDF7); // fond des cartes blanches
  static const bordureCarte = Color(0xFFDDD3BA); // bordure fine des cartes blanches
  static const vertCoche = Color(0xFF3F8A2E); // pastille cochée « en ordre »
  static const vertAuto = Color(0xFF2B6A22); // texte et icône de la pastille « Auto »
  static const vertPale = Color(0xFFE3EFD3); // encarts d'information, pastille « Auto »

  // Frise du carnet et tampon
  static const friseTrait = Color(0xFFD9CFB4); // trait vertical de la frise
  static const friseFait = Color(0xFF7FB36F); // rond « terminé »
  static const friseNeutre = Color(0xFFA79C80); // rond « action manuelle »
  static const tamponBordure = Color(0xFFB7A98A); // bordure du tampon
  static const tamponTexte = Color(0xFF8F8366); // texte du tampon

  // États
  static const ambre = Color(0xFFD9992B); // alerte « à regarder » (triangle)
  static const ambreFonce = Color(0xFFB07418); // thermomètre
  static const ambreEncre = Color(0xFF2A1B00); // point d'exclamation sur ambre
  static const flamme = Color(0xFFA93A25); // fond de l'alerte flamme
  static const flammeTrait = Color(0xFF8E2B18); // icône flamme

  /// Voile derrière la feuille de confirmation : encre à 54,9 % (valeur du design).
  static const voile = Color(0x8C14281A);
}
