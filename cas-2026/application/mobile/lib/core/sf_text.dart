import 'package:flutter/painting.dart';

import 'sf_colors.dart';

/// Échelle typographique du design v2 (Sora pour les titres et chiffres, Nunito pour le texte).
/// Tailles en dp, relevées sur les écrans du design (écran de 360 dp).
abstract final class SfText {
  // letterSpacing et height sont posés explicitement : sinon Material y ajoute son espacement par défaut
  // (0,25 dp), ce qui élargit tous les textes par rapport au design (les largeurs du PDF = celles des polices).
  static TextStyle _sora(double size, FontWeight w, Color c) =>
      TextStyle(fontFamily: 'Sora', fontSize: size, fontWeight: w, color: c, letterSpacing: 0, height: 1.2);
  static TextStyle _nunito(double size, FontWeight w, Color c) =>
      TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, letterSpacing: 0, height: 1.2);

  // --- Sora : titres, chiffres, boutons ---
  static final chiffreGeant = _sora(60, FontWeight.w700, SfColors.foret); // « 26 » °C
  // Les gros titres (30 à 36 dp) sont resserrés de 0,01 em dans le design ; en dessous de 24 dp, aucun espacement.
  static final hero36 = _sora(36, FontWeight.w700, SfColors.kraft).copyWith(letterSpacing: -0.36); // « Bonjour. Je veille… »
  static final hero33 = _sora(33, FontWeight.w700, SfColors.kraft).copyWith(letterSpacing: -0.33); // « Vos tomates vont bien. »
  static final titre30 = _sora(30, FontWeight.w700, SfColors.encre).copyWith(letterSpacing: -0.30); // « Je lance l'arrosage. »
  static final titre24 = _sora(24, FontWeight.w700, SfColors.encre); // « Eau pour 2 jours et demi »
  static final titreEcran = _sora(22, FontWeight.w700, SfColors.foret); // « Arrosage », « Sécurité »
  static final titreFeuille = _sora(22, FontWeight.w700, SfColors.encre); // « Combien de temps ? »
  static final titre20 = _sora(20, FontWeight.w700, SfColors.encre);
  static final bouton = _sora(18, FontWeight.w800, SfColors.encre);
  static final valeur = _sora(16, FontWeight.w700, SfColors.encre); // « 37 % »
  static final heure = _sora(15, FontWeight.w700, SfColors.encre); // « 11:42 »
  static final tampon = _sora(13, FontWeight.w800, SfColors.tamponTexte).copyWith(letterSpacing: 0.57); // « 7 jours gardés »
  // Capitales : espacement de 0,9 dp entre les lettres (mesuré sur « AUJOURD'HUI » et « HIER »).
  static final etiquetteCaps = _sora(13, FontWeight.w800, SfColors.texteDoux).copyWith(letterSpacing: 0.9); // « À REGARDER »

  // --- Nunito : texte ---
  static final enteteDate = _nunito(14.5, FontWeight.w700, SfColors.kraft); // « Samedi 14 novembre »
  static final enteteSalut = _nunito(17, FontWeight.w700, SfColors.kraft); // « Bon après-midi »
  static final enteteLieu = _nunito(14.5, FontWeight.w600, SfColors.kraft); // « Ma serre · il y a 2 min »
  static final titreLigne = _nunito(18, FontWeight.w700, SfColors.encre); // « Le sol »
  static final corps17 = _nunito(17, FontWeight.w600, SfColors.texteDoux);
  static final puceLabel = _nunito(17, FontWeight.w700, SfColors.encre); // « 10 min »
  static final corps16 = _nunito(16, FontWeight.w600, SfColors.texteFort);
  static final lien = _nunito(16, FontWeight.w800, SfColors.eau); // « Annuler »
  static final lienCourt = _nunito(14.5, FontWeight.w800, SfColors.eau); // « Tout »
  static final sousTitre = _nunito(15, FontWeight.w600, SfColors.texteDoux); // « Assez humide »
  static final note = _nunito(14.5, FontWeight.w600, SfColors.texteDoux); // « La serre décide seule. »
  static final alerte = _nunito(19, FontWeight.w600, const Color(0xFFFFFFFF)); // « L'alarme sonne sur place… »
  static final etiquetteMode = _nunito(14, FontWeight.w800, SfColors.vertAuto); // « Auto »
  static final segment = _nunito(16, FontWeight.w700, SfColors.kraft); // « Auto », « Manuel »
  // Interligne de 19 dp : Flutter arrondit chaque ligne à un nombre entier de dp (19 ou 20), le design alterne 19 et 20.
  static final explication = _nunito(14, FontWeight.w600, SfColors.encreVerte).copyWith(height: 19 / 14); // « Pourquoi ce matin ? … »
  static final titreCarte = _nunito(16, FontWeight.w700, SfColors.encre); // « Vanne d'eau »
  static final sousTitreCarte = _nunito(14, FontWeight.w600, SfColors.texteDoux); // « Fermée · dernier arrosage 07:10 »
  static final etiquetteOnglet = _nunito(13, FontWeight.w700, SfColors.texteDoux); // « Serre »
}
