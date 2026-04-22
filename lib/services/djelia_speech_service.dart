import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Djelia speech integration for:
/// - ASR (transcription)
/// - TTS (speech synthesis)
///
/// Configure at build/runtime with:
/// --dart-define=DJELIA_API_KEY=YOUR_KEY
/// --dart-define=DJELIA_BASE_URL=https://djelia.cloud
class DjeliaSpeechService {
  static const String _baseUrl = String.fromEnvironment(
    'DJELIA_BASE_URL',
    defaultValue: 'https://djelia.cloud',
  );

  static const String _apiKey = String.fromEnvironment('DJELIA_API_KEY');

  static const Duration _requestTimeout = Duration(seconds: 60);
  static const Duration _playbackTimeout = Duration(seconds: 75);
  static const int _maxCachedTtsItems = 24;

  static final DjeliaSpeechService _instance = DjeliaSpeechService._internal();

  factory DjeliaSpeechService() => _instance;

  DjeliaSpeechService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Cache keeps bytes + resolved format (important when v2 falls back to v1).
  final Map<String, _SynthesisResult> _ttsCache = {};
  final Map<String, Future<_SynthesisResult>> _pendingTts = {};

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Map<String, String> get _authHeaders => {'x-api-key': _apiKey};

  /// ASR transcription.
  ///
  /// Uses V2 endpoint by default:
  /// POST /api/v2/models/transcribe
  ///
  /// If [useV2] is false:
  /// POST /api/v1/models/transcribe
  ///
  /// API response can be either:
  /// - {"text": "..."} OR
  /// - [{"text": "...", "start": 0.0, "end": 1.0}, ...]
  Future<String> transcribe(
    Uint8List audioBytes, {
    bool translateToFrench = false,
    bool useV2 = true,
    String fileName = 'audio.wav',
  }) async {
    _ensureConfigured();

    final version = useV2 ? 'v2' : 'v1';
    final uri = Uri.parse(
      '$_baseUrl/api/$version/models/transcribe'
      '?translate_to_french=$translateToFrench',
    );

    final request =
        http.MultipartRequest('POST', uri)
          ..headers.addAll(_authHeaders)
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              audioBytes,
              filename: fileName,
            ),
          );

    final streamed = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Djelia ASR error ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic data = json.decode(response.body);

    if (data is Map<String, dynamic>) {
      return (data['text'] ?? '').toString().trim();
    }

    if (data is List) {
      final chunks =
          data
              .whereType<Map>()
              .map((e) => (e['text'] ?? '').toString().trim())
              .where((t) => t.isNotEmpty)
              .toList();

      return chunks.join(' ').trim();
    }

    return '';
  }

  /// TTS synthesis (non-streaming).
  ///
  /// Uses V2 endpoint by default:
  /// POST /api/v2/models/tts
  ///
  /// If [useV2] is false, uses V1 endpoint:
  /// POST /api/v1/models/tts
  ///
  /// V2 expects [description], V1 uses [speaker].
  /// Returns raw audio bytes.
  Future<Uint8List> synthesize({
    required String text,
    bool useV2 = true,
    String description = 'Moussa speaks with a clear and friendly tone',
    String format = 'mp3',
    int speaker = 1,
    bool useCache = true,
    bool joinPending = true,
  }) async {
    final result = await _synthesizeWithMetadata(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
      useCache: useCache,
      joinPending: joinPending,
    );
    return result.bytes;
  }

  Future<_SynthesisResult> _synthesizeWithMetadata({
    required String text,
    required bool useV2,
    required String description,
    required String format,
    required int speaker,
    required bool useCache,
    required bool joinPending,
  }) async {
    _ensureConfigured();

    final cacheKey = _buildTtsCacheKey(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
    );

    if (useCache) {
      final cached = _ttsCache[cacheKey];
      if (cached != null) {
        _log(
          'TTS cache hit | requestedFormat=$format | resolvedFormat=${cached.format} | textLen=${text.length} | keyHash=${cacheKey.hashCode}',
        );
        return cached;
      }

      final pendingRequest = _pendingTts[cacheKey];
      if (joinPending && pendingRequest != null) {
        _log(
          'TTS join pending request | requestedFormat=$format | textLen=${text.length} | keyHash=${cacheKey.hashCode}',
        );
        return pendingRequest;
      }
    }

    final requestFuture = _synthesizeUncached(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
    );

    if (!useCache) {
      return requestFuture;
    }

    _pendingTts[cacheKey] = requestFuture;

    try {
      final result = await requestFuture;
      _saveToTtsCache(cacheKey, result);
      return result;
    } finally {
      _pendingTts.remove(cacheKey);
    }
  }

  /// Warm up TTS for a phrase before it is needed by the UI.
  Future<void> warmupTts({
    required String text,
    bool useV2 = true,
    String description = 'Moussa speaks with a clear and friendly tone',
    String format = 'mp3',
    int speaker = 1,
  }) async {
    await _synthesizeWithMetadata(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
      useCache: true,
      joinPending: false,
    );
  }

  /// Warm up TTS for multiple phrases sequentially.
  Future<void> warmupTtsBatch(
    List<String> texts, {
    bool useV2 = true,
    String description = 'Moussa speaks with a clear and friendly tone',
    String format = 'mp3',
    int speaker = 1,
  }) async {
    for (final text in texts) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) continue;
      await warmupTts(
        text: trimmed,
        useV2: useV2,
        description: description,
        format: format,
        speaker: speaker,
      );
    }
  }

  bool hasCachedTts({
    required String text,
    bool useV2 = true,
    String description = 'Moussa speaks with a clear and friendly tone',
    String format = 'mp3',
    int speaker = 1,
  }) {
    final cacheKey = _buildTtsCacheKey(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
    );
    return _ttsCache.containsKey(cacheKey);
  }

  void clearTtsCache() {
    _ttsCache.clear();
    _pendingTts.clear();
  }

  /// Convenience helper: synthesize + play.
  ///
  /// Includes stage-level timing logs:
  /// - synthesize
  /// - stop previous playback
  /// - play start
  /// - playback complete
  Future<void> speakText({
    required String text,
    bool useV2 = true,
    String description = 'Moussa speaks with a clear and friendly tone',
    String format = 'mp3',
    int speaker = 1,
    bool warmupOnly = false,
  }) async {
    _ensureConfigured();

    final totalSw = Stopwatch()..start();
    final stageSw = Stopwatch()..start();

    _log(
      'speakText:start | textLen=${text.length} | requestedFormat=$format | useV2=$useV2 | warmupOnly=$warmupOnly',
    );

    final synthesis = await _synthesizeWithMetadata(
      text: text,
      useV2: useV2,
      description: description,
      format: format,
      speaker: speaker,
      useCache: true,
      joinPending: false,
    );
    _log(
      'speakText:stage=synthesize:done | elapsed=${_ms(stageSw)}ms | bytes=${synthesis.bytes.length} | resolvedFormat=${synthesis.format} | source=${synthesis.source}',
    );

    if (warmupOnly) {
      totalSw.stop();
      _log('speakText:done:warmupOnly | total=${_ms(totalSw)}ms');
      return;
    }

    stageSw
      ..stop()
      ..reset()
      ..start();

    await _player.stop();
    _log('speakText:stage=stopPrevious:done | elapsed=${_ms(stageSw)}ms');

    stageSw
      ..stop()
      ..reset()
      ..start();

    final mimeType = _mimeTypeForFormat(synthesis.format);
    await _playAndAwaitCompletion(
      audioBytes: synthesis.bytes,
      mimeType: mimeType,
      format: synthesis.format,
      textLen: text.length,
    );
    _log('speakText:stage=playback:done | elapsed=${_ms(stageSw)}ms');

    totalSw.stop();
    _log('speakText:done | total=${_ms(totalSw)}ms');
  }

  Future<void> _playAndAwaitCompletion({
    required Uint8List audioBytes,
    required String mimeType,
    required String format,
    required int textLen,
  }) async {
    final completion = Completer<void>();

    late final StreamSubscription<void> completeSub;
    completeSub = _player.onPlayerComplete.listen((_) {
      if (!completion.isCompleted) {
        completion.complete();
      }
    });

    try {
      final playSw = Stopwatch()..start();

      await _player.play(BytesSource(audioBytes, mimeType: mimeType));
      _log(
        'speakText:stage=play:startConfirmed | elapsed=${_ms(playSw)}ms | format=$format | textLen=$textLen',
      );

      await completion.future.timeout(
        _playbackTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Playback completion not received within ${_playbackTimeout.inSeconds}s '
            '(format=$format, textLen=$textLen, bytes=${audioBytes.length}).',
            _playbackTimeout,
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) rethrow;
      throw Exception('Audio playback failed before completion: $e');
    } finally {
      await completeSub.cancel();
    }
  }

  Future<_SynthesisResult> _synthesizeUncached({
    required String text,
    required bool useV2,
    required String description,
    required String format,
    required int speaker,
  }) async {
    if (!useV2) {
      final v1Response = await _postTtsV1(text: text, speaker: speaker);
      if (v1Response.statusCode != 200) {
        throw Exception(
          'Djelia TTS v1 error ${v1Response.statusCode}: ${v1Response.body}',
        );
      }

      return _SynthesisResult(
        bytes: v1Response.bodyBytes,
        format: 'wav',
        source: 'v1',
      );
    }

    try {
      final v2Response = await _postTtsV2(
        text: text,
        description: description,
        format: format,
      );

      if (v2Response.statusCode != 200) {
        throw Exception(
          'Djelia TTS v2 error ${v2Response.statusCode}: ${v2Response.body}',
        );
      }

      return _SynthesisResult(
        bytes: v2Response.bodyBytes,
        format: format,
        source: 'v2',
      );
    } on TimeoutException catch (_) {
      _log(
        'TTS v2 timeout -> fallback to v1 | requestedFormat=$format | textLen=${text.length}',
      );

      final v1Response = await _postTtsV1(text: text, speaker: speaker);
      if (v1Response.statusCode != 200) {
        throw Exception(
          'Djelia TTS fallback v1 error ${v1Response.statusCode}: ${v1Response.body}',
        );
      }

      return _SynthesisResult(
        bytes: v1Response.bodyBytes,
        format: 'wav',
        source: 'v1-fallback',
      );
    }
  }

  Future<http.Response> _postTtsV2({
    required String text,
    required String description,
    required String format,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v2/models/tts');
    final body = <String, dynamic>{
      'text': text,
      'description': description,
      'format': format,
    };

    final sw = Stopwatch()..start();
    _log(
      'TTS HTTP:start | url=$uri | format=$format | textLen=${text.length} | useV2=true',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_requestTimeout);

      sw.stop();
      _log(
        'TTS HTTP:response | status=${response.statusCode} | elapsed=${_ms(sw)}ms | bytes=${response.bodyBytes.length} | endpoint=v2',
      );
      return response;
    } on TimeoutException catch (_) {
      throw TimeoutException(
        'Djelia TTS HTTP timeout after ${_requestTimeout.inSeconds}s '
        '(url=$uri, format=$format, textLen=${text.length}, endpoint=v2).',
        _requestTimeout,
      );
    }
  }

  Future<http.Response> _postTtsV1({
    required String text,
    required int speaker,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/models/tts');
    final body = <String, dynamic>{'text': text, 'speaker': speaker};

    final sw = Stopwatch()..start();
    _log(
      'TTS HTTP:start | url=$uri | format=wav | textLen=${text.length} | useV2=false',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {..._authHeaders, 'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(_requestTimeout);

      sw.stop();
      _log(
        'TTS HTTP:response | status=${response.statusCode} | elapsed=${_ms(sw)}ms | bytes=${response.bodyBytes.length} | endpoint=v1',
      );
      return response;
    } on TimeoutException catch (_) {
      throw TimeoutException(
        'Djelia TTS HTTP timeout after ${_requestTimeout.inSeconds}s '
        '(url=$uri, format=wav, textLen=${text.length}, endpoint=v1).',
        _requestTimeout,
      );
    }
  }

  String _buildTtsCacheKey({
    required String text,
    required bool useV2,
    required String description,
    required String format,
    required int speaker,
  }) {
    return '${useV2 ? 'v2' : 'v1'}|$format|$speaker|$description|$text';
  }

  void _saveToTtsCache(String key, _SynthesisResult result) {
    if (_ttsCache.length >= _maxCachedTtsItems) {
      _ttsCache.remove(_ttsCache.keys.first);
    }
    _ttsCache[key] = result;
  }

  Future<void> stopSpeaking() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await stopSpeaking();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw Exception(
        'DJELIA_API_KEY is not configured. Pass it with --dart-define.',
      );
    }
  }

  String _mimeTypeForFormat(String format) {
    switch (format) {
      case 'wav':
      case 'wav_8k':
        return 'audio/wav';
      case 'ulaw_8k':
        return 'audio/basic';
      case 'mp3':
      default:
        return 'audio/mpeg';
    }
  }

  int _ms(Stopwatch sw) => sw.elapsedMilliseconds;

  void _log(String message) {
    debugPrint('[DjeliaSpeechService] $message');
  }
}

class _SynthesisResult {
  final Uint8List bytes;
  final String format;
  final String source;

  const _SynthesisResult({
    required this.bytes,
    required this.format,
    required this.source,
  });
}
