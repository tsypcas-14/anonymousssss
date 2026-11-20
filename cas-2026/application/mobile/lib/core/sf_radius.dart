import 'package:flutter/painting.dart';

/// Rayons « coins en feuille » : deux grands coins opposés (haut-gauche, bas-droite) et deux petits.
/// Valeurs mesurées sur le design v2 (dp, écran de 360 dp).
abstract final class SfRadius {
  static BorderRadius feuille(double grand, double petit) => BorderRadius.only(
        topLeft: Radius.circular(grand),
        topRight: Radius.circular(petit),
        bottomRight: Radius.circular(grand),
        bottomLeft: Radius.circular(petit),
      );

  static final BorderRadius bouton = feuille(22, 7);
  static final BorderRadius puce = feuille(18, 5);
  static final BorderRadius pastille = feuille(16, 5); // pastille de l'onglet actif

  /// Feuille de confirmation qui monte du bas : seuls les coins du haut sont arrondis.
  static const BorderRadius feuilleDuBas = BorderRadius.vertical(top: Radius.circular(30));
}
