import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sf_colors.dart';
import '../../core/sf_icon.dart';
import '../../core/sf_icons.dart';
import '../../core/sf_text.dart';
import '../../core/widgets/sf_data_row.dart';
import '../../core/widgets/sf_state_badge.dart';
import 'serre_data.dart';
import 'serre_header.dart';

/// Écran « Serre » (accueil) : l'état de la serre en un coup d'œil. Reproduction de l'écran
/// « tout va bien » du design v2 ; les valeurs viennent de [SerreData] (exemple du design pour l'instant).
class SerrePage extends StatelessWidget {
  SerrePage({super.key, SerreData? data, this.onAlertes, this.onReglages, this.onLigne}) : data = data ?? SerreData.exemple();

  final SerreData data;
  final VoidCallback? onAlertes;
  final VoidCallback? onReglages;

  /// Ouvre le détail d'une ligne (rang dans la liste : 0 le sol, 1 le réservoir, 2 l'air et la lumière…).
  final void Function(int rang)? onLigne;

  /// Hauteur de la barre d'état dans les maquettes ; une barre plus haute pousse l'en-tête vers le bas.
  static const double _barreEtatDesign = 34;

  /// Les lignes commencent 5,9 dp sous l'en-tête et le pied de page tient jusqu'à la barre du bas (688 dp).
  static const double _espaceSousEntete = 5.9;
  static const double _hauteurPied = 46.1;

  /// Hauteur de la page dans la maquette : en-tête 336 + espace + lignes (60 dp, 63 dp avec un état) + pied 46,1 dp.
  /// Tout va bien : 688 dp ; avec deux lignes à regarder, 693 dp (la page défile alors de 5 dp).
  static double _hauteurContenuDesign(SerreData d) =>
      336 + _espaceSous(d) + d.lignes.fold<double>(0, (t, l) => t + _hauteurLigne(l)) + _hauteurPied;

  static double _hauteurLigne(SerreLigne l) => l.etat == SfState.normal ? SfDataRow.hauteur : SfDataRow.hauteurAvecEtat;

  /// Espace sous l'en-tête : 5,9 dp, ou 4,9 dp quand une ligne porte un état (mesuré sur les deux maquettes).
  static double _espaceSous(SerreData d) => d.lignes.any((l) => l.etat != SfState.normal) ? 4.9 : _espaceSousEntete;

  @override
  Widget build(BuildContext context) {
    final decalage = math.max(0.0, MediaQuery.paddingOf(context).top - _barreEtatDesign);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // En-tête vert sous la barre d'état : icônes claires, fond transparent.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: data.palette.iconesClaires ? Brightness.light : Brightness.dark,
        statusBarBrightness: data.palette.iconesClaires ? Brightness.dark : Brightness.light,
      ),
      child: ColoredBox(
        color: SfColors.kraft,
        child: LayoutBuilder(builder: (context, c) {
          // Écran plus haut que la maquette : l'en-tête absorbe la différence pour ne laisser aucun vide.
          final extra = math.max(0.0, c.maxHeight - (_hauteurContenuDesign(data) + decalage));
          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SerreHeader(
                date: data.date,
                salutation: data.salutation,
                titre: data.titre,
                lieu: data.lieu,
                palette: data.palette,
                decalageHaut: decalage,
                extraBas: extra,
                onAlertes: onAlertes,
                onReglages: onReglages,
              ),
              SizedBox(height: _espaceSous(data)),
              for (var i = 0; i < data.lignes.length; i++) _ligne(i, derniere: i == data.lignes.length - 1),
              _Pied(texte: data.pied),
            ]),
          );
        }),
      ),
    );
  }

  Widget _ligne(int rang, {required bool derniere}) => _rang(data.lignes[rang], rang, derniere: derniere);

  Widget _rang(SerreLigne l, int rang, {required bool derniere}) => SfDataRow(
        icon: l.icone,
        iconColor: l.couleurIcone,
        title: l.titre,
        subtitle: l.sousTitre,
        value: l.valeur,
        state: l.etat,
        muted: l.eteinte,
        showSeparator: !derniere,
        onTap: () => onLigne?.call(rang),
      );
}

/// « ⊕ La serre décide seule. Rien à faire. » : le volant, réduit, puis la phrase.
class _Pied extends StatelessWidget {
  const _Pied({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SerrePage._hauteurPied,
      child: Stack(children: [
        // Volant à 77 % du design : boîte de 18,5 dp à (24,8 ; 10,7).
        Positioned(left: 24.8, top: 10.7, child: SfIcon(SfIcons.volant, color: SfColors.texteDoux, scale: 0.77)),
        Positioned(
          left: 52,
          top: 0,
          child: Baseline(
            baseline: 25,
            baselineType: TextBaseline.alphabetic,
            child: Text(texte, style: SfText.note, maxLines: 1, softWrap: false),
          ),
        ),
      ]),
    );
  }
}
