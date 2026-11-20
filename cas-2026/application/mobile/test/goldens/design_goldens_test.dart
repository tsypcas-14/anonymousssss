import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/core/sf_colors.dart';
import 'package:smartfarm/core/sf_icons.dart';
import 'package:smartfarm/core/sf_theme.dart';
import 'package:smartfarm/core/widgets/sf_bottom_nav.dart';
import 'package:smartfarm/core/widgets/sf_button.dart';
import 'package:smartfarm/core/widgets/sf_confirm_sheet.dart';
import 'package:smartfarm/core/widgets/sf_data_row.dart';
import 'package:smartfarm/core/widgets/sf_equipment_card.dart';
import 'package:smartfarm/core/widgets/sf_explain_card.dart';
import 'package:smartfarm/core/widgets/sf_state_badge.dart';
import 'package:smartfarm/features/aeration/aeration_page.dart';
import 'package:smartfarm/features/alerte/alertes_page.dart';
import 'package:smartfarm/features/alerte/flamme_page.dart';
import 'package:smartfarm/features/arrosage/arrosage_page.dart';
import 'package:smartfarm/features/arrosage/en_cours_data.dart';
import 'package:smartfarm/features/arrosage/en_cours_page.dart';
import 'package:smartfarm/features/capteurs/air_page.dart';
import 'package:smartfarm/features/capteurs/capteur_muet_page.dart';
import 'package:smartfarm/features/capteurs/sol_page.dart';
import 'package:smartfarm/features/carnet/carnet_page.dart';
import 'package:smartfarm/features/demarrage/bienvenue_page.dart';
import 'package:smartfarm/features/demarrage/chargement_page.dart';
import 'package:smartfarm/features/demarrage/connecter_page.dart';
import 'package:smartfarm/features/fin/erreur_page.dart';
import 'package:smartfarm/features/fin/securite_page.dart';
import 'package:smartfarm/features/fin/succes_page.dart';
import 'package:smartfarm/features/hors_ligne/hors_ligne_page.dart';
import 'package:smartfarm/features/plantes/plantes_page.dart';
import 'package:smartfarm/features/reglages/aide_page.dart';
import 'package:smartfarm/features/reglages/reglages_page.dart';
import 'package:smartfarm/features/reglages/seuils_page.dart';
import 'package:smartfarm/features/serre/serre_data.dart';
import 'package:smartfarm/features/serre/serre_page.dart';

/// Images de référence des composants, rendues dans un cadre de 360x756 dp (écran du design v2), 3 px par dp.
/// Elles servent à (1) comparer visuellement avec les maquettes (voir README du design system) et
/// (2) détecter toute régression : `flutter test` échoue si un composant change.
/// Pour regénérer : `flutter test --update-goldens test/goldens`.
final _cle = GlobalKey();

/// Capture en 3 px par dp dans build/golden_x3/ (non versionné), pour comparer finement avec le PDF du design.
Future<void> _x3(WidgetTester tester, String nom) async {
  await tester.runAsync(() async {
    final b = _cle.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/golden_x3/$nom.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _cadre(WidgetTester tester, List<Widget> enfants, {Color fond = SfColors.kraft}) async {
  tester.view.physicalSize = const Size(1080, 2268);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSfTheme(),
    home: Scaffold(backgroundColor: fond, body: RepaintBoundary(key: _cle, child: ColoredBox(color: fond, child: Stack(children: enfants)))),
  ));
  await tester.pump();
}

Widget _enBas(Widget w) => Positioned(left: 0, right: 0, bottom: 0, child: w);
Widget _a(double top, Widget w, {double left = 0, double? right = 0}) => Positioned(top: top, left: left, right: right, child: w);

/// Dans `flutter test`, les polices du projet ne sont pas chargées d'office (le texte serait dessiné en
/// rectangles). On charge ici les vraies polices du design.
Future<void> _chargerPolices() async {
  const familles = {
    'Sora': ['Sora-Bold.ttf', 'Sora-ExtraBold.ttf'],
    'Nunito': ['Nunito-Medium.ttf', 'Nunito-SemiBold.ttf', 'Nunito-Bold.ttf', 'Nunito-ExtraBold.ttf'],
  };
  for (final e in familles.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_chargerPolices);

  testWidgets('lignes de donnée + barre (Accueil, tout va bien)', (tester) async {
    await _cadre(tester, [
      _a(341.9, Column(children: [
        SfDataRow(icon: SfIcons.sol, iconColor: SfColors.terre, title: 'Le sol', subtitle: 'Assez humide', value: '37 %', onTap: () {}),
        SfDataRow(icon: SfIcons.reservoir, iconColor: SfColors.eau, title: 'Le réservoir', subtitle: 'Eau pour 2 jours et demi', value: '41 %', onTap: () {}),
        SfDataRow(icon: SfIcons.air, iconColor: SfColors.ambreFonce, title: "L'air et la lumière", subtitle: 'Il fait 26 °C, ciel voilé', onTap: () {}),
        SfDataRow(icon: SfIcons.securite, iconColor: SfColors.flammeTrait, title: 'Sécurité', subtitle: 'Pas de flamme', onTap: () {}),
        SfDataRow(icon: SfIcons.plantes, iconColor: SfColors.grisDoux, title: 'Santé des plantes', subtitle: 'Bientôt', muted: true, showSeparator: false, onTap: () {}),
      ])),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'accueil_lignes');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('accueil_lignes.png'));
  });

  testWidgets('lignes avec état « à regarder »', (tester) async {
    await _cadre(tester, [
      _a(340.9, Column(children: [
        SfDataRow(icon: SfIcons.sol, iconColor: SfColors.terre, title: 'Le sol', subtitle: 'Un peu sec', value: '27 %', state: SfState.warning, onTap: () {}),
        SfDataRow(icon: SfIcons.reservoir, iconColor: SfColors.eau, title: 'Le réservoir', subtitle: 'Bientôt bas', value: '19 %', state: SfState.warning, onTap: () {}),
      ])),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'lignes_a_regarder');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('lignes_a_regarder.png'));
  });

  testWidgets('bouton plein + lien + barre (Arrosage)', (tester) async {
    await _cadre(tester, [
      _a(561.9, SfButton(label: 'Arroser maintenant', icon: SfIcons.arrosage, onPressed: () {}), left: 24, right: 24),
      _a(625.9, SfLink(label: 'Voir les arrosages de la semaine', onPressed: () {})),
      _enBas(SfBottomNav(currentIndex: 1, onTap: (_) {})),
    ]);
    await _x3(tester, 'bouton_plein_lien');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('bouton_plein_lien.png'));
  });

  testWidgets('bouton contour (Arrêter)', (tester) async {
    await _cadre(tester, [
      _a(609.9, SfButton(label: 'Arrêter', variant: SfButtonVariant.contour, onPressed: () {}), left: 24, right: 24),
      _enBas(SfBottomNav(currentIndex: 1, onTap: (_) {})),
    ]);
    await _x3(tester, 'bouton_contour');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('bouton_contour.png'));
  });

  testWidgets('carte de confirmation', (tester) async {
    await _cadre(tester, [
      _a(455.9, SfConfirmSheet(
        title: 'Combien de temps ?',
        choices: const ['5 min', '10 min', '15 min'],
        selectedIndex: 1,
        onChoice: (_) {},
        confirmLabel: 'Arroser 10 minutes',
        confirmIcon: SfIcons.arrosage,
        note: 'Vous prenez la main. Retour en auto dans 1 h.',
        onConfirm: () {},
        onCancel: () {},
      )),
    ]);
    await _x3(tester, 'carte_confirmation');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('carte_confirmation.png'));
  });

  testWidgets('barre du bas, onglet Carnet actif', (tester) async {
    await _cadre(tester, [_enBas(SfBottomNav(currentIndex: 3, onTap: (_) {}))]);
    await _x3(tester, 'barre_carnet');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('barre_carnet.png'));
  });

  testWidgets('écran Serre complet (accueil, tout va bien)', (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: SerrePage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'serre_accueil');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('serre_accueil.png'));
  });

  testWidgets('écran Arrosage complet', (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: ArrosagePage()),
      _enBas(SfBottomNav(currentIndex: 1, onTap: (_) {})),
    ]);
    await _x3(tester, 'arrosage');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('arrosage.png'));
  });

  testWidgets("cartes « Pourquoi » et « Vanne d'eau »", (tester) async {
    // Positions de l'écran Arrosage de la première version du design : 16 dp de marge, cartes à 145,9 et 233,9 dp.
    await _cadre(tester, [
      _a(145.9, const SfExplainCard(
        lead: 'Pourquoi ce matin ?',
        body: ' À 07:10, le sol était à 18 %. Le seuil est à 30 %, alors la serre a arrosé 8 minutes.',
      ), left: 16, right: 16),
      _a(233.9, SfEquipmentCard(icon: SfIcons.vanne, title: "Vanne d'eau", subtitle: 'Fermée · dernier arrosage 07:10', onTap: () {}),
          left: 16, right: 16),
    ]);
    await _x3(tester, 'cartes_pourquoi_vanne');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('cartes_pourquoi_vanne.png'));
  });

  testWidgets('écran Le carnet complet', (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: CarnetPage()),
      _enBas(SfBottomNav(currentIndex: 3, onTap: (_) {})),
    ]);
    await _x3(tester, 'carnet');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('carnet.png'));
  });

  testWidgets("écran Je lance l'arrosage", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: EnCoursPage(data: EnCoursData.manuel(minutes: 10, heure: '14:34'))),
      _enBas(SfBottomNav(currentIndex: 1, onTap: (_) {})),
    ]);
    await _x3(tester, 'en_cours');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('en_cours.png'));
  });

  testWidgets('écran Serre, état « à regarder »', (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: SerrePage(data: SerreData.aRegarder())),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'serre_a_regarder');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('serre_a_regarder.png'));
  });

  testWidgets('alerte flamme (plein écran)', (tester) async {
    await _cadre(tester, [Positioned.fill(child: FlammePage())], fond: SfColors.flamme);
    await _x3(tester, 'flamme');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('flamme.png'));
  });

  testWidgets("écran Le sol", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: SolPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'capteur_sol');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('capteur_sol.png'));
  });

  testWidgets("écran L'air et la lumière", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: AirPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'capteur_air');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('capteur_air.png'));
  });

  testWidgets("écran Capteur muet", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: CapteurMuetPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'capteur_muet');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('capteur_muet.png'));
  });

  testWidgets("écran Aération", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: AerationPage()),
      _enBas(SfBottomNav(currentIndex: 2, onTap: (_) {})),
    ]);
    await _x3(tester, 'aeration');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('aeration.png'));
  });

  testWidgets("écran Alertes", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: AlertesPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'alertes');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('alertes.png'));
  });

  testWidgets("écran Réglages", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: ReglagesPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'reglages');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('reglages.png'));
  });

  testWidgets("écran Ce que la serre surveille", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: SeuilsPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'seuils');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('seuils.png'));
  });

  testWidgets("écran Santé des plantes", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: PlantesPage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'plantes');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('plantes.png'));
  });

  testWidgets("écran Hors ligne", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: HorsLignePage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'hors_ligne');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('hors_ligne.png'));
  });

  testWidgets("écran Aide", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: AidePage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'aide');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('aide.png'));
  });

  testWidgets("écran Chargement", (tester) async {
    await _cadre(tester, [Positioned.fill(child: ChargementPage())]);
    await _x3(tester, 'chargement');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('chargement.png'));
  });

  testWidgets("écran Bienvenue", (tester) async {
    await _cadre(tester, [Positioned.fill(child: BienvenuePage())], fond: SfColors.foret);
    await _x3(tester, 'bienvenue');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('bienvenue.png'));
  });

  testWidgets("écran Connecter ma serre", (tester) async {
    await _cadre(tester, [Positioned.fill(child: ConnecterPage())]);
    await _x3(tester, 'connecter');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('connecter.png'));
  });

  testWidgets("écran Succès", (tester) async {
    await _cadre(tester, [Positioned.fill(child: SuccesPage())], fond: SfColors.vertPale);
    await _x3(tester, 'succes');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('succes.png'));
  });

  testWidgets("écran Erreur", (tester) async {
    await _cadre(tester, [Positioned.fill(child: ErreurPage())]);
    await _x3(tester, 'erreur');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('erreur.png'));
  });

  testWidgets("écran Sécurité", (tester) async {
    await _cadre(tester, [
      Positioned(top: 0, left: 0, right: 0, bottom: 68, child: SecuritePage()),
      _enBas(SfBottomNav(currentIndex: 0, onTap: (_) {})),
    ]);
    await _x3(tester, 'securite');
    await expectLater(find.byType(Scaffold), matchesGoldenFile('securite.png'));
  });
}
