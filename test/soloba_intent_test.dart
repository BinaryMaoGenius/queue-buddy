import 'package:flutter_test/flutter_test.dart';
import 'package:projet_queue_bancaire/services/soloba_service.dart';

void main() {
  final soloba = SolobaService();

  group('Soloba Intent Analysis Tests', () {
    test('Should detect Versement from various phrases', () {
      final phrases = [
        "wari don",
        "n'bɛ wari don",
        "n'b'a fɛ ka wari ladi",
        "versement",
        "n'b'a fɛ ka wari dɔni don n'ka compte la"
      ];
      for (final p in phrases) {
        expect(soloba.analyzeIntent(p).serviceId, 'versement', reason: "Failed for: $p");
      }
    });

    test('Should detect Retrait from various phrases', () {
      final phrases = [
        "wari bɔ",
        "n'bɛ wari bo",
        "retrait d'argent",
        "wari bɔli",
        "n'bakatɔ ka wari bɔ"
      ];
      for (final p in phrases) {
        expect(soloba.analyzeIntent(p).serviceId, 'retrait', reason: "Failed for: $p");
      }
    });

    test('Should detect Virement from various phrases', () {
      final phrases = [
        "wari ci",
        "transfert wari",
        "virement bancaire",
        "n'b'a fɛ ka wari cili kɛ"
      ];
      for (final p in phrases) {
        expect(soloba.analyzeIntent(p).serviceId, 'virement', reason: "Failed for: $p");
      }
    });

    test('Should detect Renseignement from various phrases', () {
      final phrases = [
        "wari hakɛ ɲini",
        "n'b'a fɛ ka ɲɛfɔli sɔrɔ",
        "renseignement s'il vous plaît",
        "info sur mon compte",
        "ɲiningali kɛ"
      ];
      for (final p in phrases) {
        expect(soloba.analyzeIntent(p).serviceId, 'renseignement', reason: "Failed for: $p");
      }
    });

    test('Should return "autre" for unknown or ambiguous phrases', () {
      final phrases = [
        "bonjour",
        "i ni ce",
        "est-ce qu'il y a du monde ?",
        "..."
      ];
      for (final p in phrases) {
        expect(soloba.analyzeIntent(p).serviceId, 'autre', reason: "Failed for: $p");
      }
    });
  });
}
