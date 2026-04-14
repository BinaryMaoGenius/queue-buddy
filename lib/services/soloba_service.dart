import 'package:http/http.dart' as http;
import 'dart:convert';

class SolobaResult {
  final String text;
  final String bambara;
  final String serviceId;
  final double confidence;
  final String model;
  final String version;

  SolobaResult({
    required this.text,
    required this.bambara,
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
  static const String _spaceUrl = String.fromEnvironment('ASR_SPACE_URL', defaultValue: 'https://binaryMao-sira-asr.hf.space/transcribe');
  
  // 3. ENDPOINT INFERENCE API (Backup gratuit si le Space est éteint)
  static const String _hfInferenceUrl = 'https://api-inference.huggingface.co/models/RobotsMali/soloni-114m-tdt-ctc-v3';
  
  static const String _hfToken = String.fromEnvironment('HF_TOKEN');
  
  // Noms de modèles pour le tracking des résultats
  static const String modelName = "Soloni-ASR";
  static const String modelVersion = "v3-ctc";

  Future<SolobaResult> recognizeSpeech(List<int> audioBytes) async {
    // Ordre de priorité : Space (Dédié) > Local (Dev) > Inference API (Backup)
    
    // Essayer d'abord le Space HF (Production)
    try {
      print("[Soloba] Tentative ASR Space HF...");
      return await _recognizeAtUrl(_spaceUrl, audioBytes);
    } catch (e) {
      print("[Soloba] ASR Space échouée ou non configurée : $e");
      
      // Essayer le serveur local (Développement)
      try {
        print("[Soloba] Tentative ASR Locale...");
        return await _recognizeAtUrl(_localEndpoint, audioBytes);
      } catch (localErr) {
        print("[Soloba] ASR Locale échouée : $localErr");
        
        // Enfin, essayer l'Inference API (Dernier recours)
        try {
          print("[Soloba] Tentative ASR Inference API (Backup)...");
          return await _recognizeInferenceApi(audioBytes);
        } catch (infErr) {
          print("[Soloba] ASR Inference API échouée : $infErr");
          throw Exception("Tous les services ASR sont indisponibles. Vérifiez votre connexion.");
        }
      }
    }
  }

  // Pour les serveurs personnalisés (Space ou Local)
  Future<SolobaResult> _recognizeAtUrl(String url, List<int> audioBytes) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: 'audio.wav',
    ));
    
    // Ajouter le token si disponible (nécessaire si le Space n'est pas public)
    if (_hfToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_hfToken';
    }

    print("[Soloba] Envoi de l'audio (${audioBytes.length} octets) vers $url...");
    var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    var response = await http.Response.fromStream(streamedResponse);
    print("[Soloba] Réponse reçue. Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      dynamic data = json.decode(response.body);
      String transcribedText = (data is List && data.isNotEmpty) ? (data[0]['text'] ?? "Inconnu") : (data['text'] ?? "Inconnu");
      return analyzeIntent(transcribedText);
    } else {
      throw Exception("Serveur ASR ($url) Erreur: ${response.statusCode} - ${response.body}");
    }
  }

  // Pour l'Inference API de Hugging Face (requiert un body binaire)
  Future<SolobaResult> _recognizeInferenceApi(List<int> audioBytes) async {
    final headers = {'Content-Type': 'application/octet-stream'};
    if (_hfToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_hfToken';
    }

    print("[Soloba] Envoi vers Inference API (${audioBytes.length} octets)...");
    final response = await http.post(
      Uri.parse(_hfInferenceUrl),
      headers: headers,
      body: audioBytes,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      dynamic data = json.decode(response.body);
      String transcribedText = (data is List && data.isNotEmpty) ? (data[0]['text'] ?? "Inconnu") : (data['text'] ?? "Inconnu");
      return analyzeIntent(transcribedText);
    } else {
      throw Exception("Inference API Erreur: ${response.statusCode} - ${response.body}");
    }
  }

  SolobaResult analyzeIntent(String transcribedText) {
    // Normalisation du texte
    final String input = transcribedText.toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('?', "")
      .replaceAll('!', "")
      .replaceAll(',', " ");

    final List<String> words = input.split(' ').where((w) => w.length > 1).toList();
    
    // Mapping des intentions (Synonymes Bambara & Français)
    final Map<String, List<String>> mapping = {
      'versement': ['don', 'donli', 'ladi', 'versement', 'depot', 'se'],
      'retrait': ['bo', 'bɔ', 'bɔli', 'retrait', 'argent'],
      'virement': ['ci', 'cili', 'virement', 'transfert'],
      'renseignement': ['ɲini', 'ɲɛfɔli', 'nyefoli', 'kalo', 'renseignement', 'info', 'hakɛ', 'niningali'],
    };

    String bestId = "autre";
    String bestLabel = "Service Client";
    double bestScore = 0;

    // Calcul du score par catégorie
    mapping.forEach((serviceId, keywords) {
      double score = 0;
      for (final keyword in keywords) {
        if (input.contains(keyword)) {
          // Plus de poids si le mot exact est présent isolément
          score += (words.contains(keyword)) ? 1.0 : 0.5;
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestId = serviceId;
        bestLabel = getServiceLabel(serviceId);
      }
    });

    // Seuil de confiance minimal (ajustable)
    if (bestScore < 0.5) {
      bestId = "autre";
      bestLabel = "Service Client";
    }

    return SolobaResult(
      text: bestLabel,
      bambara: transcribedText,
      serviceId: bestId,
      confidence: bestScore > 1.0 ? 1.0 : bestScore, 
      model: modelName,
      version: modelVersion,
    );
  }

  String getServiceLabel(String id) {
    switch (id) {
      case 'versement': return "Versement";
      case 'retrait': return "Retrait";
      case 'virement': return "Virement";
      case 'renseignement': return "Renseignement";
      default: return "Service Client";
    }
  }
}
