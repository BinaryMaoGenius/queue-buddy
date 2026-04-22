import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'djelia_speech_service.dart';

class SolobaResult {
  final String text;
  final String bambara;
  final String labelBambara; // Nouveau : Label court en Bambara
  final String serviceId;
  final double confidence;
  final String model;
  final String version;

  SolobaResult({
    required this.text,
    required this.bambara,
    required this.labelBambara,
    required this.serviceId,
    required this.confidence,
    required this.model,
    required this.version,
  });
}

class SolobaService {
  // 1. ENDPOINT LOCAL (Pour le développement)
  static const String _localEndpoint = 'http://localhost:8000/transcribe';

  // 2. ENDPOINT SPACE HF (Votre serveur dédié en prod)
  // Basé sur votre compte : https://huggingface.co/binaryMao
  static const String _spaceUrl = String.fromEnvironment(
    'ASR_SPACE_URL',
    defaultValue: 'https://binaryMao-sira-asr.hf.space/transcribe',
  );

  // 3. ENDPOINT INFERENCE API (Backup gratuit si le Space est éteint)
  static const String _hfToken = String.fromEnvironment('HF_TOKEN');

  // Modèle NLU pour la compréhension sémantique (Multilingue)
  static const String _hfNluUrl =
      'https://api-inference.huggingface.co/models/MoritzLaurer/mDeBERTa-v3-base-mnli-xnli';

  final DjeliaSpeechService _djelia = DjeliaSpeechService();

  // Noms de modèles pour le tracking des résultats
  static const String modelName = "Soloni-ASR";
  static const String modelVersion = "v3-ctc";

  Future<SolobaResult> recognizeSpeech(List<int> audioBytes) async {
    // Ordre de priorité : Djelia (principal) > Space (dédié) > Local (dev) > Inference API (backup)

    // 0) Djelia ASR (prioritaire)
    try {
      if (_djelia.isConfigured) {
        print("[Soloba] Tentative ASR Djelia v2...");
        final text = await _djelia.transcribe(
          Uint8List.fromList(audioBytes),
          translateToFrench: true, // On récupère le français pour mieux comprendre l'action
          useV2: true,
        );
        if (text.trim().isNotEmpty) {
          return await analyzeIntent(text);
        }
        throw Exception("Transcription Djelia vide");
      } else {
        print("[Soloba] DJELIA_API_KEY non configurée, fallback activé.");
      }
    } catch (e) {
      print("[Soloba] ASR Djelia échouée : $e");
    }

    // 1) Space HF (production)
    try {
      print("[Soloba] Tentative ASR Space HF...");
      return await _recognizeAtUrl(_spaceUrl, audioBytes);
    } catch (e) {
      print("[Soloba] ASR Space échouée ou non configurée : $e");

      // 2) Serveur local (développement)
      try {
        print("[Soloba] Tentative ASR Locale...");
        return await _recognizeAtUrl(_localEndpoint, audioBytes);
      } catch (localErr) {
        print("[Soloba] ASR Locale échouée : $localErr");

        // 3) Inference API (dernier recours)
        try {
          print("[Soloba] Tentative ASR Inference API (Backup)...");
          return await _recognizeInferenceApi(audioBytes);
        } catch (infErr) {
          print("[Soloba] ASR Inference API échouée : $infErr");
          throw Exception(
            "Tous les services ASR sont indisponibles. Vérifiez votre connexion.",
          );
        }
      }
    }
  }

  // Pour les serveurs personnalisés (Space ou Local)
  Future<SolobaResult> _recognizeAtUrl(String url, List<int> audioBytes) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(
      http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'),
    );

    // Ajouter le token si disponible (nécessaire si le Space n'est pas public)
    if (_hfToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_hfToken';
    }

    print(
      "[Soloba] Envoi de l'audio (${audioBytes.length} octets) vers $url...",
    );
    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    var response = await http.Response.fromStream(streamedResponse);
    print("[Soloba] Réponse reçue. Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      dynamic data = json.decode(response.body);
      String transcribedText =
          (data is List && data.isNotEmpty)
              ? (data[0]['text'] ?? "Inconnu")
              : (data['text'] ?? "Inconnu");
      return analyzeIntent(transcribedText);
    } else {
      throw Exception(
        "Serveur ASR ($url) Erreur: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<SolobaResult> _recognizeInferenceApi(List<int> audioBytes) async {
    final headers = {'Content-Type': 'application/octet-stream'};
    if (_hfToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_hfToken';
    }

    final inferenceUrl =
        'https://api-inference.huggingface.co/models/RobotsMali/soloni-114m-tdt-ctc-v3';

    print("[Soloba] Envoi vers Inference API (${audioBytes.length} octets)...");
    final response = await http
        .post(Uri.parse(inferenceUrl), headers: headers, body: audioBytes)
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      dynamic data = json.decode(response.body);
      String transcribedText =
          (data is List && data.isNotEmpty)
              ? (data[0]['text'] ?? "Inconnu")
              : (data['text'] ?? "Inconnu");
      return analyzeIntent(transcribedText);
    } else {
      throw Exception(
        "Inference API Erreur: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<SolobaResult> analyzeIntent(String transcribedText) async {
    // 1. Tenter la compréhension sémantique via l'IA (Multilingue)
    if (_hfToken.isNotEmpty) {
      try {
        print("[Soloba] Tentative de compréhension sémantique via l'IA...");
        final aiResult = await _analyzeIntentWithAI(transcribedText).timeout(
          const Duration(seconds: 4),
        );
        if (aiResult.confidence > 0.6) {
          print(
            "[Soloba] AI Success: ${aiResult.serviceId} (conf: ${aiResult.confidence})",
          );
          return aiResult;
        }
        print("[Soloba] IA incertaine (conf: ${aiResult.confidence}), fallback.");
      } catch (e) {
        print("[Soloba] Échec IA NLU : $e. Fallback sur les mots-clés.");
      }
    }

    // 2. Fallback sur le dictionnaire de mots-clés enrichi (votre "bibliothèque")
    return _analyzeIntentWithKeywords(transcribedText);
  }

  Future<SolobaResult> _analyzeIntentWithAI(String text) async {
    final headers = {
      'Authorization': 'Bearer $_hfToken',
      'Content-Type': 'application/json',
    };

    // Nous définissons des labels descriptifs en français pour une meilleure précision NLU
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

    final response = await http.post(Uri.parse(_hfNluUrl),
        headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String bestLabel = data['labels'][0];
      final double confidence = (data['scores'][0] as num).toDouble();
      final String serviceId = labelToId[bestLabel] ?? "autre";

      return SolobaResult(
        text: getServiceLabel(serviceId),
        bambara: text,
        labelBambara: getServiceLabelBambara(serviceId),
        serviceId: serviceId,
        confidence: confidence,
        model: "NLU-mDeBERTa",
        version: "v3",
      );
    } else {
      throw Exception("Erreur NLU HF: ${response.statusCode}");
    }
  }

  SolobaResult _analyzeIntentWithKeywords(String transcribedText) {
    // Normalisation du texte (plus agressive)
    final String input = transcribedText
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('?', "")
        .replaceAll('!', "")
        .replaceAll('.', "")
        .replaceAll(',', " ")
        .replaceAll('ɔ', "o") // Tolérance orthographe Bambara
        .replaceAll('ɛ', "e")
        .replaceAll('ɲ', "ny")
        .trim();

    final List<String> words =
        input.split(' ').where((w) => w.length > 1).toList();

    print("[Soloba Debug] Transcription reçue: \"$transcribedText\"");
    print("[Soloba Debug] Texte normalisé: \"$input\"");

    // Mapping des intentions (Bibliothèque élargie Bambara & Français)
    final Map<String, List<String>> mapping = {
      'versement': [
        'don',
        'donli',
        'donni',
        'wari don',
        'ladi',
        'versement',
        'depot',
        'doli',
        'se',
        'remplir',
        'verse',
        'déposer',
        'mettre',
        'ajout',
      ],
      'retrait': [
        'bo',
        'bɔ',
        'boili',
        'bɔli',
        'wari bo',
        'wari bɔ',
        'retrait',
        'argent',
        'enlever',
        'retirer',
        'sortir',
      ],
      'virement': [
        'ci',
        'cili',
        'wari ci',
        'virement',
        'transfert',
        'envoi',
        'envoyer',
        'transférer',
        'envoyé',
      ],
      'renseignement': [
        'ɲini',
        'nyini',
        'nyinikali',
        'ɲɛfɔli',
        'nyefoli',
        'kalo',
        'kibaru',
        'ko',
        'kunu',
        'renseignement',
        'info',
        'hakɛ',
        'niningali',
        'question',
        'information',
        'connaître',
        'demander',
        'savoir',
      ],
    };

    String bestId = "autre";
    String bestLabel = "Service Client";
    double bestScore = 0;

    // Calcul du score par catégorie
    mapping.forEach((serviceId, keywords) {
      double score = 0;
      for (final keyword in keywords) {
        if (input.contains(keyword)) {
          // Les expressions multi-mots (ex: "wari don") valent plus
          bool isMultiWord = keyword.contains(' ');
          if (isMultiWord) {
            score += 1.5;
          } else {
            // Plus de poids si le mot exact est présent isolément
            score += (words.contains(keyword)) ? 1.0 : 0.5;
          }
        }
      }

      if (score > 0) {
        print("[Soloba Debug] Score pour $serviceId: $score");
      }

      if (score > bestScore) {
        bestScore = score;
        bestId = serviceId;
        bestLabel = getServiceLabel(serviceId);
      }
    });

    // Seuil de confiance minimal (abaissé pour plus de tolérance)
    if (bestScore < 0.4) {
      bestId = "autre";
      bestLabel = "Service Client";
    }

    return SolobaResult(
      text: bestLabel,
      bambara: transcribedText,
      labelBambara: getServiceLabelBambara(bestId),
      serviceId: bestId,
      confidence: bestScore > 1.0 ? 1.0 : bestScore,
      model: modelName,
      version: modelVersion,
    );
  }

  String getServiceLabel(String id) {
    switch (id) {
      case 'versement':
        return "Versement";
      case 'retrait':
        return "Retrait";
      case 'virement':
        return "Virement";
      case 'renseignement':
        return "Renseignement";
      default:
        return "Service Client";
    }
  }

  String getServiceLabelBambara(String id) {
    switch (id) {
      case 'versement':
        return "Wari don";
      case 'retrait':
        return "Wari bɔ";
      case 'virement':
        return "Wari ci";
      case 'renseignement':
        return "Ɲɛfɔli";
      default:
        return "Baarakɛla";
    }
  }
}
