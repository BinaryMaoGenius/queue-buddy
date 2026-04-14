import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projet_queue_bancaire/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Prise de ticket complète', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // 1. Vérifier qu'on est sur la page d'accueil
      expect(find.text('SIRA'), findsOneWidget);

      // Attendre que le chargement soit fini (si présent)
      while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // 2. Trouver et cliquer sur une agence par son nom (la première dans le Mock)
      await tester.tap(find.textContaining('Siège').first);
      await tester.pump(const Duration(seconds: 1));

      // 3. Cliquer sur "PRENDRE UN TICKET" qui est apparu (on prend le premier bouton élevé trouvé)
      await tester.tap(find.byType(ElevatedButton).at(0));
      await tester.pump(const Duration(seconds: 2));

      // 4. Vérifier qu'on est sur la page de prise de ticket
      expect(find.textContaining('Services'), findsAtLeast(1));

      // 5. Sélectionner un service (ex: Versement)
      final serviceItem = find.text('Versement').first;
      await tester.ensureVisible(serviceItem);
      await tester.tap(serviceItem);
      await tester.pump(const Duration(seconds: 1));

      // 6. Remplir le formulaire
      await tester.enterText(find.byType(TextFormField).at(0), 'Jean Dupont');
      await tester.enterText(find.byType(TextFormField).at(1), '70000000');
      await tester.pump(const Duration(milliseconds: 500));

      // 7. Cliquer sur le bouton de validation qui est apparu
      final confirmBtn = find.textContaining('PRENDRE MON TICKET').first;
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      
      // On attend la simulation de lag du Mock Mode (800ms) + transition
      await tester.pump(const Duration(seconds: 5));

      // 8. Vérifier la présence du titre du ticket (AppBar)
      expect(find.textContaining('TICKET'), findsAtLeast(1));
    });
  });
}
