import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/app.dart';
import 'package:smartfarm/core/widgets/sf_bottom_nav.dart';
import 'package:smartfarm/features/arrosage/arrosage_page.dart';
import 'package:smartfarm/features/aeration/aeration_page.dart';
import 'package:smartfarm/features/capteurs/air_page.dart';
import 'package:smartfarm/features/reglages/contact_flamme.dart';
import 'package:smartfarm/core/widgets/sf_confirm_sheet.dart';
import 'package:smartfarm/features/capteurs/sol_page.dart';
import 'package:smartfarm/features/serre/serre_page.dart';

void main() {
  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2268);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmartFarmApp(depart: '/serre'));
    await tester.pumpAndSettle();
  }

  testWidgets('toucher « Le sol » ouvre l\'écran Le sol, la flèche revient à l\'accueil', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Le sol'));
    await tester.pumpAndSettle();
    expect(find.byType(SolPage), findsOneWidget);
    expect(find.text('assez humide '), findsNothing); // le texte est dans un TextSpan
    expect(find.byType(SerrePage), findsNothing);

    await tester.tap(find.bySemanticsLabel('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(SerrePage), findsOneWidget);
  });

  testWidgets('toucher « L\'air et la lumière » ouvre l\'écran Air', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text("L'air et la lumière"));
    await tester.pumpAndSettle();
    expect(find.byType(AirPage), findsOneWidget);
  });

  testWidgets("la cloche ouvre Alertes ; l'onglet Aération s'affiche", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Alertes'));
    await tester.pumpAndSettle();
    expect(find.text('À REGARDER'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Retour'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Aération')));
    await tester.pumpAndSettle();
    expect(find.text('Ventilateur arrêté'), findsOneWidget);
  });

  testWidgets("toucher « Le réservoir » ouvre l'onglet Arrosage", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Le réservoir'));
    await tester.pumpAndSettle();
    expect(find.byType(ArrosagePage), findsOneWidget);
    expect(find.byType(SerrePage), findsNothing);
  });

  testWidgets('le bouton Réglages ouvre Réglages, puis « Ce que la serre surveille »', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('ME PRÉVENIR'), findsOneWidget);
    await tester.tap(find.text('Tout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ce que la serre surveille'));
    await tester.pumpAndSettle();
    expect(find.text("Sous 30 % d'humidité, la serre arrose."), findsOneWidget);
  });

  testWidgets("« Le réservoir est bientôt bas » (Alertes) ouvre l'onglet Arrosage", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Alertes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le réservoir est bientôt bas'));
    await tester.pumpAndSettle();
    expect(find.byType(ArrosagePage), findsOneWidget);
  });

  testWidgets("toucher « Santé des plantes » ouvre l'écran Santé des plantes", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Santé des plantes'));
    await tester.pumpAndSettle();
    expect(find.text('Bientôt, la serre regardera vos plants.'), findsOneWidget);
  });

  testWidgets("Réglages > Aide : toucher une question ouvre sa réponse", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aide'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Activez le partage de connexion'), findsOneWidget);
    await tester.tap(find.text("La vanne ne s'ouvre pas"));
    await tester.pumpAndSettle();
    expect(find.textContaining('Activez le partage de connexion'), findsNothing);
    expect(find.textContaining('Vérifiez que le réservoir'), findsOneWidget);
  });

  testWidgets("toucher « Sécurité » ouvre l'écran Sécurité", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Sécurité'));
    await tester.pumpAndSettle();
    expect(find.text('Pas de flamme dans la serre.'), findsOneWidget);
  });

  testWidgets("premier lancement : Chargement, puis Bienvenue, puis Connecter ma serre, puis l'accueil", (tester) async {
    tester.view.physicalSize = const Size(1080, 2268);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmartFarmApp());
    await tester.pump();
    expect(find.text('Je cherche la serre…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour.'), findsOneWidget);
    await tester.tap(find.text('Connecter ma serre'));
    await tester.pumpAndSettle();
    expect(find.text('Trois petites choses, une seule fois.'), findsOneWidget);
    await tester.tap(find.text("C'est parti"));
    await tester.pumpAndSettle();
    expect(find.byType(SerrePage), findsOneWidget);
  });

  testWidgets("Arrosage : la cloche ouvre Alertes, « Voir les arrosages de la semaine » ouvre le Carnet", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Arrosage')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Alertes'));
    await tester.pumpAndSettle();
    expect(find.text('À REGARDER'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Arrosage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir les arrosages de la semaine'));
    await tester.pumpAndSettle();
    expect(find.text('Le carnet'), findsWidgets);
    expect(find.byType(ArrosagePage), findsNothing);
  });

  testWidgets("Aération : la cloche ouvre Alertes", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Aération')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Alertes'));
    await tester.pumpAndSettle();
    expect(find.text('À REGARDER'), findsOneWidget);
  });

  testWidgets("« Aérer maintenant » ouvre la carte de durée, puis le suivi de l'aération", (tester) async {
    await ouvrir(tester);
    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Aération')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aérer maintenant'));
    await tester.pumpAndSettle();
    expect(find.byType(SfConfirmSheet), findsOneWidget);
    expect(find.text('Aérer 20 minutes'), findsOneWidget);
    await tester.tap(find.text('Aérer 20 minutes'));
    await tester.pumpAndSettle();
    expect(find.text("Je lance l'aération."), findsOneWidget);
    await tester.tap(find.text('Arrêter'));
    await tester.pumpAndSettle();
    expect(find.byType(AerationPage), findsOneWidget);
  });

  testWidgets("Réglages > Contact : on change le nom et le numéro, tout l'app le reprend", (tester) async {
    contactFlamme.value = const ContactFlamme(nom: 'Responsable', numero: '+216 00 000 000');
    addTearDown(() => contactFlamme.value = const ContactFlamme(nom: 'Responsable', numero: '+216 00 000 000'));
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact en cas de flamme'));
    await tester.pumpAndSettle();
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), 'Amel');
    await tester.enterText(champs.at(1), '+216 11 111 111');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(contactFlamme.value.nom, 'Amel');
    expect(find.text('Amel'), findsOneWidget); // la ligne de Réglages montre le nouveau nom
  });

  testWidgets("Contact : un numéro trop court est refusé", (tester) async {
    contactFlamme.value = const ContactFlamme(nom: 'Responsable', numero: '+216 00 000 000');
    await ouvrir(tester);
    await tester.tap(find.bySemanticsLabel('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact en cas de flamme'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Entrez un nom et un numéro valide.'), findsOneWidget);
    expect(contactFlamme.value.numero, '+216 00 000 000');
  });

  test('le numéro est masqué au milieu', () {
    expect(masquer('+216 00 000 000'), '+216 00 ••• 000');
    expect(numeroValide('12'), isFalse);
    expect(numeroValide('+216 00 000 000'), isTrue);
  });
}
