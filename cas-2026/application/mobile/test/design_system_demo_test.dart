import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/core/sf_theme.dart';
import 'package:smartfarm/core/widgets/sf_confirm_sheet.dart';
import 'package:smartfarm/features/demo/design_system_demo_page.dart';

void main() {
  testWidgets("l'écran de démonstration s'affiche et défile sans erreur", (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(theme: buildSfTheme(), home: const DesignSystemDemoPage()));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Défilement jusqu'en bas : aucune erreur de mise en page (débordement, contraintes).
    final liste = find.byType(ListView);
    for (var i = 0; i < 12; i++) {
      await tester.drag(liste, const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'erreur après le défilement n°$i');
    }
  });

  testWidgets('la carte de confirmation s\'ouvre et le choix de durée met à jour le bouton', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(theme: buildSfTheme(), home: const DesignSystemDemoPage()));
    await tester.scrollUntilVisible(find.text('Ouvrir la carte'), 400, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Ouvrir la carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir la carte'));
    await tester.pumpAndSettle();

    expect(find.byType(SfConfirmSheet), findsOneWidget);
    expect(find.text('Arroser 10 minutes'), findsOneWidget);

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    expect(find.text('Arroser 15 minutes'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(SfConfirmSheet), findsNothing);
  });
}
