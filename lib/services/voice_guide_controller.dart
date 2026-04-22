import 'dart:async';

import 'djelia_speech_service.dart';

/// Priority used to arbitrate competing voice guide requests.
enum VoiceGuidePriority { low, normal, high, critical }

/// Outcome of a voice guide request.
enum VoiceGuideStatus {
  played,
  skippedEmpty,
  skippedNotConfigured,
  skippedCooldown,
  preempted,
  superseded,
  failed,
}

class VoiceGuideResult {
  final VoiceGuideStatus status;
  final String reason;

  const VoiceGuideResult(this.status, this.reason);

  bool get isPlayed => status == VoiceGuideStatus.played;

  @override
  String toString() => 'VoiceGuideResult(status: $status, reason: $reason)';
}

class VoiceGuideDebugSnapshot {
  final DateTime timestamp;
  final String? currentScope;
  final int pendingCount;
  final Map<String, VoiceGuideResult> lastResultByScope;

  const VoiceGuideDebugSnapshot({
    required this.timestamp,
    required this.currentScope,
    required this.pendingCount,
    required this.lastResultByScope,
  });

  @override
  String toString() {
    return 'VoiceGuideDebugSnapshot('
        'timestamp: $timestamp, '
        'currentScope: $currentScope, '
        'pendingCount: $pendingCount, '
        'lastResultByScope: $lastResultByScope'
        ')';
  }
}

/// Global controller for voice guides with:
/// - cooldown enforcement
/// - priority arbitration
/// - preemption of lower-priority playback
/// - request coalescing per scope
class VoiceGuideController {
  static final VoiceGuideController _instance =
      VoiceGuideController._internal();

  factory VoiceGuideController() => _instance;

  VoiceGuideController._internal();

  final DjeliaSpeechService _speech = DjeliaSpeechService();

  final List<_VoiceGuideTask> _pending = <_VoiceGuideTask>[];
  final Map<String, DateTime> _lastPlayedByScope = <String, DateTime>{};
  final Map<String, VoiceGuideResult> _lastResultByScope =
      <String, VoiceGuideResult>{};
  final StreamController<VoiceGuideDebugSnapshot> _debugController =
      StreamController<VoiceGuideDebugSnapshot>.broadcast();

  _VoiceGuideTask? _currentTask;
  bool _isPumping = false;
  int _sessionToken = 0;

  /// Default minimum delay between two voice guides.
  Duration globalCooldown = const Duration(milliseconds: 1200);

  /// Request a voice guide for a screen/scope.
  ///
  /// [scopeKey] should uniquely identify a UI scope (e.g. "home", "ticket").
  /// [minReplayInterval] prevents repeating the same scope too frequently.
  /// [force] bypasses cooldown checks for this request.
  Future<VoiceGuideResult> request({
    required String scopeKey,
    required String text,
    VoiceGuidePriority priority = VoiceGuidePriority.normal,
    Duration minReplayInterval = const Duration(seconds: 12),
    bool force = false,
    bool immediate = false,
    String description =
        'Moussa speaks with a very clear voice and friendly tone',
    String format = 'mp3',
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      const result = VoiceGuideResult(
        VoiceGuideStatus.skippedEmpty,
        'Empty guide text.',
      );
      _lastResultByScope[scopeKey] = result;
      _emitDebug();
      return result;
    }

    if (!_speech.isConfigured) {
      const result = VoiceGuideResult(
        VoiceGuideStatus.skippedNotConfigured,
        'DJELIA_API_KEY is missing.',
      );
      _lastResultByScope[scopeKey] = result;
      _emitDebug();
      return result;
    }

    if (!force && _isScopeInCooldown(scopeKey, minReplayInterval)) {
      const result = VoiceGuideResult(
        VoiceGuideStatus.skippedCooldown,
        'Scope replay cooldown active.',
      );
      _lastResultByScope[scopeKey] = result;
      _emitDebug();
      return result;
    }

    final task = _VoiceGuideTask(
      scopeKey: scopeKey,
      text: normalizedText,
      priority: priority,
      immediate: immediate,
      description: description,
      format: format,
      requestedAt: DateTime.now(),
      completer: Completer<VoiceGuideResult>(),
    );

    _coalescePendingForScope(task);
    _enqueue(task);
    _maybePreemptCurrent(task);
    _emitDebug();

    unawaited(_pump());
    return task.completer.future;
  }

  /// Convenience for screen-level guides.
  Future<VoiceGuideResult> requestForScreen({
    required String screenId,
    required String text,
    VoiceGuidePriority priority = VoiceGuidePriority.normal,
    Duration minReplayInterval = const Duration(seconds: 12),
    bool force = false,
    bool immediate = false,
  }) {
    return request(
      scopeKey: 'screen:$screenId',
      text: text,
      priority: priority,
      minReplayInterval: minReplayInterval,
      force: force,
      immediate: immediate,
    );
  }

  /// Stops current playback and clears pending requests.
  Future<void> stopAll() async {
    _sessionToken++;
    _completeCurrentAs(
      const VoiceGuideResult(
        VoiceGuideStatus.preempted,
        'Stopped by controller.',
      ),
    );

    for (final task in _pending) {
      _completeTask(
        task,
        const VoiceGuideResult(VoiceGuideStatus.superseded, 'Queue cleared.'),
      );
    }
    _pending.clear();

    await _speech.stopSpeaking();
  }

  /// Clears only queued tasks, optionally stopping current playback.
  Future<void> clearQueue({bool stopCurrent = false}) async {
    for (final task in _pending) {
      _completeTask(
        task,
        const VoiceGuideResult(
          VoiceGuideStatus.superseded,
          'Removed from queue.',
        ),
      );
    }
    _pending.clear();

    if (stopCurrent) {
      await stopAll();
    } else {
      _emitDebug();
    }
  }

  Stream<VoiceGuideDebugSnapshot> get debugStream => _debugController.stream;

  VoiceGuideDebugSnapshot get currentDebugSnapshot => VoiceGuideDebugSnapshot(
    timestamp: DateTime.now(),
    currentScope: _currentTask?.scopeKey,
    pendingCount: _pending.length,
    lastResultByScope: Map.unmodifiable(_lastResultByScope),
  );

  Map<String, VoiceGuideResult> get lastResultByScope =>
      Map.unmodifiable(_lastResultByScope);

  bool _isScopeInCooldown(String scopeKey, Duration minReplayInterval) {
    final last = _lastPlayedByScope[scopeKey];
    if (last == null) return false;
    return DateTime.now().difference(last) < minReplayInterval;
  }

  void _coalescePendingForScope(_VoiceGuideTask incoming) {
    // Keep only the newest request per scope in pending queue.
    for (int i = _pending.length - 1; i >= 0; i--) {
      final task = _pending[i];
      if (task.scopeKey == incoming.scopeKey) {
        _pending.removeAt(i);
        _completeTask(
          task,
          const VoiceGuideResult(
            VoiceGuideStatus.superseded,
            'Superseded by a newer request in the same scope.',
          ),
        );
      }
    }
  }

  void _enqueue(_VoiceGuideTask task) {
    _pending.add(task);
    _pending.sort((a, b) {
      final byImmediate = (b.immediate ? 1 : 0).compareTo(a.immediate ? 1 : 0);
      if (byImmediate != 0) return byImmediate;
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      return a.requestedAt.compareTo(b.requestedAt);
    });
  }

  void _maybePreemptCurrent(_VoiceGuideTask incoming) {
    final current = _currentTask;
    if (current == null) return;

    final isImmediateCritical =
        incoming.immediate && incoming.priority == VoiceGuidePriority.critical;
    final isHigherPriority = incoming.priority.index > current.priority.index;

    if (!isImmediateCritical && !isHigherPriority) return;

    _sessionToken++;
    _completeCurrentAs(
      VoiceGuideResult(
        VoiceGuideStatus.preempted,
        isImmediateCritical
            ? 'Preempted by immediate critical request: ${incoming.scopeKey}.'
            : 'Preempted by higher priority request: ${incoming.scopeKey}.',
      ),
    );

    unawaited(_speech.stopSpeaking());
  }

  Future<void> _pump() async {
    if (_isPumping) return;
    _isPumping = true;

    try {
      while (true) {
        if (_currentTask != null) break;
        if (_pending.isEmpty) break;

        final next = _pending.removeAt(0);
        _currentTask = next;
        final localToken = ++_sessionToken;

        final wait = _remainingGlobalCooldown();
        if (!next.immediate && wait > Duration.zero) {
          await Future.delayed(wait);
        }

        if (_currentTask != next || localToken != _sessionToken) {
          // Preempted before start.
          _completeTask(
            next,
            const VoiceGuideResult(
              VoiceGuideStatus.preempted,
              'Preempted before playback start.',
            ),
          );
          continue;
        }

        final startedAt = DateTime.now();

        try {
          await _speech.speakText(
            text: next.text,
            description: next.description,
            format: next.format,
          );

          // If session changed while we were awaiting, request was preempted.
          if (localToken != _sessionToken || _currentTask != next) {
            _completeTask(
              next,
              const VoiceGuideResult(
                VoiceGuideStatus.preempted,
                'Preempted during playback.',
              ),
            );
            continue;
          }

          _lastPlayedByScope[next.scopeKey] = startedAt;
          _completeTask(
            next,
            const VoiceGuideResult(
              VoiceGuideStatus.played,
              'Voice guide played.',
            ),
          );
        } catch (e) {
          _completeTask(
            next,
            VoiceGuideResult(VoiceGuideStatus.failed, 'Playback failed: $e'),
          );
        } finally {
          if (_currentTask == next) {
            _currentTask = null;
          }
        }
      }
    } finally {
      _isPumping = false;
    }
  }

  Duration _remainingGlobalCooldown() {
    if (_lastPlayedByScope.isEmpty) {
      return Duration.zero;
    }

    // Use latest played timestamp among scopes to enforce global cadence.
    DateTime latest = _lastPlayedByScope.values.first;
    for (final t in _lastPlayedByScope.values) {
      if (t.isAfter(latest)) latest = t;
    }

    final elapsed = DateTime.now().difference(latest);
    final remaining = globalCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _completeCurrentAs(VoiceGuideResult result) {
    final current = _currentTask;
    if (current == null) return;
    _completeTask(current, result);
    _currentTask = null;
  }

  void _completeTask(_VoiceGuideTask task, VoiceGuideResult result) {
    _lastResultByScope[task.scopeKey] = result;
    _emitDebug();

    if (!task.completer.isCompleted) {
      task.completer.complete(result);
    }
  }

  void _emitDebug() {
    if (_debugController.isClosed) return;

    _debugController.add(
      VoiceGuideDebugSnapshot(
        timestamp: DateTime.now(),
        currentScope: _currentTask?.scopeKey,
        pendingCount: _pending.length,
        lastResultByScope: Map.unmodifiable(_lastResultByScope),
      ),
    );
  }

  Future<void> disposeDebugStream() async {
    if (!_debugController.isClosed) {
      await _debugController.close();
    }
  }
}

class _VoiceGuideTask {
  final String scopeKey;
  final String text;
  final VoiceGuidePriority priority;
  final bool immediate;
  final String description;
  final String format;
  final DateTime requestedAt;
  final Completer<VoiceGuideResult> completer;

  _VoiceGuideTask({
    required this.scopeKey,
    required this.text,
    required this.priority,
    required this.immediate,
    required this.description,
    required this.format,
    required this.requestedAt,
    required this.completer,
  });
}
