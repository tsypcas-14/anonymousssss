import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/app.dart';
import 'package:smartfarm/core/widgets/sf_bottom_nav.dart';
import 'package:smartfarm/core/widgets/sf_confirm_sheet.dart';
import 'package:smartfarm/features/arrosage/arrosage_page.dart';

void main() {
  /// Ouvre l'application sur l'onglet Arrosage, avec un écran de la taille des maquettes (360 x 756 dp).
  Future<void> ouvrirArrosage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2268);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmartFarmApp(depart: '/serre'));
    await tester.pumpAndSettle();
    // L'onglet de la barre du bas (le titre de l'écran porte aussi le texte « Arrosage »).
    await tester.tap(find.descendant(of: find.byType(SfBottomNav), matching: find.text('Arrosage')));
    await tester.pumpAndSettle();
  }

  testWidgets('« Arroser maintenant » ouvre la carte « Combien de temps ? » avec 10 min choisi', (tester) async {
    await ouvrirArrosage(tester);
    expect(find.byType(SfConfirmSheet), findsNothing);

    await tester.tap(find.text('Arroser maintenant'));
    await tester.pumpAndSettle();

    expect(find.byType(SfConfirmSheet), findsOneWidget);
    expect(find.text('Combien de temps ?'), findsOneWidget);
    for (final duree in ['5 min', '10 min', '15 min']) {
      expect(find.text(duree), findsOneWidget);
    }
    expect(find.text('Arroser 10 minutes'), findsOneWidget);
    expect(find.text('Vous prenez la main. Retour en auto dans 1 h.'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('choisir 15 min met à jour le bouton, Annuler ferme la carte sans arroser', (tester) async {
    await ouvrirArrosage(tester);
    await tester.tap(find.text('Arroser maintenant'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    expect(find.text('Arroser 15 minutes'), findsOneWidget);
    expect(find.text('Arroser 10 minutes'), findsNothing);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(SfConfirmSheet), findsNothing);
  });

  testWidgets('confirmer ferme la carte et renvoie la durée choisie', (tester) async {
    int? duree;
    tester.view.physicalSize = const Size(1080, 2268);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Page seule, pour observer le rappel `onArroser`.
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ArrosagePage(onArroser: (m) => duree = m))));
    await tester.tap(find.text('Arroser maintenant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroser 5 minutes'));
    await tester.pumpAndSettle();

    expect(find.byType(SfConfirmSheet), findsNothing);
    expect(duree, 5);
  });

  testWidgets("confirmer ouvre « Je lance l'arrosage. » ; Arrêter puis la flèche ramènent à l'écran Arrosage", (tester) async {
    await ouvrirArrosage(tester);
    await tester.tap(find.text('Arroser maintenant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroser 15 minutes'));
    await tester.pumpAndSettle();

    // Suivi de la commande : la durée choisie est reprise, les quatre étapes sont là, la barre du bas reste affichée.
    expect(find.text("Je lance l'arrosage."), findsOneWidget);
    expect(find.text('15 minutes, à la main.'), findsOneWidget);
    for (final etape in ['Ordre envoyé', "La serre l'a reçu", "La vanne s'ouvre…", "L'eau coule"]) {
      expect(find.text(etape), findsOneWidget);
    }
    expect(find.text('Pendant 15 minutes'), findsOneWidget);
    expect(find.byType(SfBottomNav), findsOneWidget);
    expect(find.byType(SfConfirmSheet), findsNothing);

    // « Arrêter » revient à l'écran Arrosage.
    await tester.tap(find.text('Arrêter'));
    await tester.pumpAndSettle();
    expect(find.text("Je lance l'arrosage."), findsNothing);
    expect(find.text('Arroser maintenant'), findsOneWidget);

    // Même parcours, retour par la flèche.
    await tester.tap(find.text('Arroser maintenant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arroser 10 minutes'));
    await tester.pumpAndSettle();
    expect(find.text("Je lance l'arrosage."), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Arroser maintenant'), findsOneWidget);
  });
}
