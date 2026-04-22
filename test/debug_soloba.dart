import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Simulation simplifiée du service pour tester sans l'environnement Flutter complet
void main() async {
  const String hfToken = String.fromEnvironment('HF_TOKEN');
  const String hfNluUrl = 'https://api-inference.huggingface.co/models/MoritzLaurer/mDeBERTa-v3-base-mnli-xnli';

  // Liste de tests (phrases en bambara transcrites en français par Djelia ou directement)
  final testPhrases = [
    "Je veux verser de l'argent sur mon compte",
    "Retrait d'argent s'il vous plaît",
    "Faire un virement à mon frère",
    "Je voudrais des informations sur mon solde",
    "Wari don",
    "Wari bo"
  ];

  print("--- DEBUG SOLOBA AI NLU ---");

  for (final text in testPhrases) {
    try {
      final result = await analyzeWithAI(text, hfToken, hfNluUrl);
      print("\nPHRASE: \"$text\"");
      print("INTENTION: ${result['id']} (Conf: ${result['score'].toStringAsFixed(2)})");
    } catch (e) {
      print("Erreur pour \"$text\": $e");
    }
  }
}

Future<Map<String, dynamic>> analyzeWithAI(String text, String token, String url) async {
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  final Map<String, String> labelToId = {
    "Faire un versement d'argent ou un dépôt sur le compte": "versement",
    "Effectuer un retrait d'argent au guichet": "retrait",
    "Faire un virement bancaire ou un transfert d'argent": "virement",
    "Demander une information ou un renseignement au service client": "renseignement",
  };

  final body = json.encode({
    "inputs": text,
    "parameters": {"candidate_labels": labelToId.keys.toList()},
  });

  final response = await http.post(Uri.parse(url), headers: headers, body: body);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final String bestLabel = data['labels'][0];
    final double confidence = (data['scores'][0] as num).toDouble();
    return {
      'id': labelToId[bestLabel],
      'score': confidence
    };
  } else {
    throw Exception("HTTP ${response.statusCode}: ${response.body}");
  }
}
