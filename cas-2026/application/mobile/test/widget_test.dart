import 'package:flutter_test/flutter_test.dart';
import 'package:smartfarm/app.dart';
import 'package:smartfarm/core/widgets/sf_bottom_nav.dart';

void main() {
  testWidgets("l'application démarre sur l'onglet Serre, écran vide, avec la barre du bas", (tester) async {
    await tester.pumpWidget(const SmartFarmApp(depart: '/serre'));
    await tester.pumpAndSettle();

    expect(find.byType(SfBottomNav), findsOneWidget);
    for (final nom in ['Serre', 'Arrosage', 'Aération', 'Carnet']) {
      expect(find.text(nom), findsOneWidget);
    }
  });

  testWidgets('toucher un onglet change de page, et la barre reste affichée', (tester) async {
    await tester.pumpWidget(const SmartFarmApp(depart: '/serre'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arrosage'));
    await tester.pumpAndSettle();
    expect(find.byType(SfBottomNav), findsOneWidget);
    final nav = tester.widget<SfBottomNav>(find.byType(SfBottomNav));
    expect(nav.currentIndex, 1);

    await tester.tap(find.text('Carnet'));
    await tester.pumpAndSettle();
    expect(tester.widget<SfBottomNav>(find.byType(SfBottomNav)).currentIndex, 3);
  });
}
