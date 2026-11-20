// GENERE a partir des tracés vectoriels du design v2 (page 10 : ecran Aeration). Coordonnees en dp, relatives a l'origine
// du groupe (indiquee en commentaire).
import 'package:flutter/painting.dart';

import '../../core/sf_forme.dart';

/// Ventilateur sur pied, a l'arret : pales, moyeu et pied. Boite de 100 x 110 dp (origine 40 ; 110).
final List<Forme> formesVentilateur = [
  Forme.trait(Ancre.gauche, Path()..moveTo(57.89,45.42)..cubicTo(57.96,45.89,57.98,46.37,57.95,46.85)..cubicTo(57.92,47.32,57.85,47.79,57.73,48.26)..cubicTo(57.61,48.72,57.45,49.17,57.24,49.6)..cubicTo(57.03,50.03,56.78,50.44,56.49,50.82)..cubicTo(56.21,51.2,55.88,51.55,55.53,51.87)..cubicTo(55.17,52.19,54.79,52.47,54.37,52.71)..cubicTo(53.96,52.95,53.53,53.15,53.08,53.31)..cubicTo(52.63,53.47,52.16,53.58,51.69,53.65)..cubicTo(51.22,53.72,50.74,53.74,50.26,53.71)..cubicTo(49.78,53.68,49.31,53.61,48.85,53.49)..cubicTo(48.39,53.37,47.94,53.2,47.51,53)..cubicTo(47.08,52.79,46.67,52.54,46.29,52.25)..cubicTo(45.91,51.96,45.56,51.64,45.24,51.29)..cubicTo(44.92,50.93,44.64,50.54,44.4,50.13)..cubicTo(44.15,49.72,43.95,49.29,43.8,48.84)..cubicTo(43.64,48.38,43.53,47.92,43.46,47.45)..cubicTo(43.39,46.97,43.37,46.5,43.4,46.02)..cubicTo(43.43,45.54,43.5,45.07,43.62,44.61)..cubicTo(43.74,44.15,43.9,43.7,44.11,43.27)..cubicTo(44.32,42.84,44.57,42.43,44.86,42.05)..cubicTo(45.14,41.67,45.47,41.32,45.82,41)..cubicTo(46.18,40.68,46.56,40.4,46.98,40.15)..cubicTo(47.39,39.91,47.82,39.71,48.27,39.55)..cubicTo(48.72,39.4,49.19,39.28,49.66,39.22)..cubicTo(50.13,39.15,50.61,39.13,51.09,39.16)..cubicTo(51.57,39.19,52.04,39.26,52.5,39.38)..cubicTo(52.96,39.5,53.41,39.66,53.84,39.87)..cubicTo(54.27,40.08,54.68,40.33,55.06,40.61)..cubicTo(55.44,40.9,55.79,41.22,56.11,41.58)..cubicTo(56.43,41.94,56.71,42.32,56.95,42.74)..cubicTo(57.2,43.15,57.4,43.58,57.55,44.03)..cubicTo(57.71,44.48,57.82,44.95,57.89,45.42), Color(0xFF6E7B66), 4.5, true),
  Forme.trait(Ancre.gauche, Path()..moveTo(49.66,39.22)..cubicTo(46.25,21.09,53.18,8.86,66.95,8.22)..cubicTo(71.46,21.87,63.67,34.22,49.66,39.22), Color(0xFF6E7B66), 4.5, true),
  Forme.trait(Ancre.gauche, Path()..moveTo(57.43,49.16)..cubicTo(74.84,55.27,81.96,67.4,75.63,79.63)..cubicTo(61.55,76.72,54.75,63.8,57.43,49.16), Color(0xFF6E7B66), 4.5, true),
  Forme.trait(Ancre.gauche, Path()..moveTo(44.93,50.92)..cubicTo(30.94,62.94,16.88,63.05,9.45,51.45)..cubicTo(19.01,40.71,33.6,41.28,44.93,50.92), Color(0xFF6E7B66), 4.5, true),
  Forme.trait(Ancre.gauche, Path()..moveTo(50.68,88.5)..lineTo(50.68,102.79)..moveTo(34.8,102.79)..lineTo(66.55,102.79), Color(0xFF6E7B66), 3.97, true),
];
