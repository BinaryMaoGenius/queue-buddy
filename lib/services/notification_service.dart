import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import 'djelia_speech_service.dart';

/// In-app notification model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type; // 'ticket_taken', '30min', '10min', 'your_turn'
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

/// Manages in-app notifications, sound alerts, and persisted "your turn" schedules.
///
/// Core behavior:
/// - When a ticket is taken, cache it locally with an estimated trigger time.
/// - Schedule a local timer for the "your turn" alert.
/// - Restore cached schedules on app relaunch and re-arm timers.
/// - If a trigger time already passed while app was closed, fire immediately on restore.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    unawaited(_restorePendingAlertsOnStartup());
  }

  static const String _pendingAlertsPrefsKey = 'pending_ticket_alerts_v1';
  static const int _defaultEstimatedWaitMinutes = 5;

  final List<AppNotification> _notifications = [];
  final _controller = StreamController<List<AppNotification>>.broadcast();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final DjeliaSpeechService _speechService = DjeliaSpeechService();

  final Map<String, _PendingTicketAlert> _pendingByTicketId = {};
  final Map<String, Timer> _timersByTicketId = {};

  // Premium Sound URLs
  static const String _soundSuccess =
      "https://cdn.pixabay.com/audio/2022/03/15/audio_73147814b7.mp3";
  static const String _soundReminder =
      "https://cdn.pixabay.com/audio/2021/08/04/audio_062123992b.mp3";
  static const String _soundYourTurn =
      "https://cdn.pixabay.com/audio/2022/11/04/audio_32c25603ca.mp3";

  Stream<List<AppNotification>> get notificationStream => _controller.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Called when a ticket is successfully taken.
  ///
  /// [estimatedWaitMinutes] drives when the "your turn" notification should fire.
  /// If not provided, a default estimate is used.
  void onTicketTaken(
    String ticketId,
    String ticketNum, {
    int? estimatedWaitMinutes,
    DateTime? createdAt,
  }) {
    _addNotification(
      title: AppStrings.notifTicketTaken,
      body: "${AppStrings.notifTicketTakenBody} ($ticketNum)",
      type: 'ticket_taken',
    );

    final estimateMinutes = (estimatedWaitMinutes ??
            _defaultEstimatedWaitMinutes)
        .clamp(1, 24 * 60);
    final startAt = createdAt ?? DateTime.now();
    final triggerAt = startAt.add(Duration(minutes: estimateMinutes));

    final alert = _PendingTicketAlert(
      ticketId: ticketId,
      ticketNum: ticketNum,
      createdAt: startAt,
      estimatedWaitMinutes: estimateMinutes,
      triggerAt: triggerAt,
    );

    _pendingByTicketId[ticketId] = alert;
    _scheduleOrFire(alert);
    unawaited(_persistPendingAlerts());
  }

  /// Called when it's the client's turn.
  void onYourTurn(String ticketNum, {String? ticketId}) {
    if (ticketId != null) {
      _cancelTimer(ticketId);
      _pendingByTicketId.remove(ticketId);
      unawaited(_persistPendingAlerts());
    }

    _addNotification(
      title: AppStrings.notifYourTurn,
      body: "${AppStrings.notifYourTurnBody} ($ticketNum)",
      type: 'your_turn',
    );

    unawaited(_speakYourTurnInBambara(ticketNum));
  }

  /// Optional: externally cancel a pending alert (e.g. ticket served/cancelled).
  Future<void> cancelPendingTicketAlert(String ticketId) async {
    _cancelTimer(ticketId);
    _pendingByTicketId.remove(ticketId);
    await _persistPendingAlerts();
  }

  /// Optional: clear all pending ticket schedules.
  Future<void> cancelAllPendingTicketAlerts() async {
    for (final ticketId in _timersByTicketId.keys.toList()) {
      _cancelTimer(ticketId);
    }
    _pendingByTicketId.clear();
    await _persistPendingAlerts();
  }

  Future<void> _speakYourTurnInBambara(String ticketNum) async {
    if (!_speechService.isConfigured) return;

    try {
      await _speechService.speakText(
        text:
            "I ka waati sera. Ticket nimɛro $ticketNum. I ka taa guichet la sisan.",
        description: "Moussa speaks with a very clear voice and friendly tone",
        format: 'mp3',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error playing Bambara TTS: $e');
    }
  }

  void _addNotification({
    required String title,
    required String body,
    required String type,
  }) {
    final notif = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notif);
    _controller.add(List.from(_notifications));
    unawaited(_playSound(type));
    debugPrint('[NotificationService] $title: $body');
  }

  Future<void> _playSound(String type) async {
    try {
      String url;
      switch (type) {
        case 'ticket_taken':
          url = _soundSuccess;
          break;
        case 'your_turn':
          url = _soundYourTurn;
          break;
        default:
          url = _soundReminder;
      }
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('[NotificationService] Error playing sound: $e');
    }
  }

  void _scheduleOrFire(_PendingTicketAlert alert) {
    final now = DateTime.now();
    final remaining = alert.triggerAt.difference(now);

    if (remaining <= Duration.zero) {
      _firePendingAlert(alert.ticketId);
      return;
    }

    _cancelTimer(alert.ticketId);
    _timersByTicketId[alert.ticketId] = Timer(remaining, () {
      _firePendingAlert(alert.ticketId);
    });

    debugPrint(
      '[NotificationService] Scheduled your-turn for ${alert.ticketNum} in ${remaining.inSeconds}s',
    );
  }

  void _firePendingAlert(String ticketId) {
    final alert = _pendingByTicketId[ticketId];
    if (alert == null) return;

    _cancelTimer(ticketId);
    _pendingByTicketId.remove(ticketId);
    unawaited(_persistPendingAlerts());

    onYourTurn(alert.ticketNum, ticketId: ticketId);
  }

  void _cancelTimer(String ticketId) {
    final timer = _timersByTicketId.remove(ticketId);
    timer?.cancel();
  }

  Future<void> _restorePendingAlertsOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingAlertsPrefsKey);

      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          if (item is Map) {
            final casted = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            _restoreOneAlert(casted);
          }
          continue;
        }
        _restoreOneAlert(item);
      }

      debugPrint(
        '[NotificationService] Restored ${_pendingByTicketId.length} pending ticket alerts',
      );
    } catch (e) {
      debugPrint('[NotificationService] Restore pending alerts failed: $e');
    }
  }

  void _restoreOneAlert(Map<String, dynamic> map) {
    try {
      final alert = _PendingTicketAlert.fromJson(map);
      _pendingByTicketId[alert.ticketId] = alert;
      _scheduleOrFire(alert);
    } catch (e) {
      debugPrint('[NotificationService] Skipped invalid pending alert: $e');
    }
  }

  Future<void> _persistPendingAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _pendingByTicketId.values.map((a) => a.toJson()).toList();
      await prefs.setString(_pendingAlertsPrefsKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('[NotificationService] Persist pending alerts failed: $e');
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _controller.add(List.from(_notifications));
  }

  void clearAll() {
    _notifications.clear();
    _controller.add(List.from(_notifications));
  }

  void dispose() {
    for (final timer in _timersByTicketId.values) {
      timer.cancel();
    }
    _timersByTicketId.clear();
    _controller.close();
  }
}

class _PendingTicketAlert {
  final String ticketId;
  final String ticketNum;
  final DateTime createdAt;
  final int estimatedWaitMinutes;
  final DateTime triggerAt;

  const _PendingTicketAlert({
    required this.ticketId,
    required this.ticketNum,
    required this.createdAt,
    required this.estimatedWaitMinutes,
    required this.triggerAt,
  });

  Map<String, dynamic> toJson() => {
    'ticket_id': ticketId,
    'ticket_num': ticketNum,
    'created_at': createdAt.toIso8601String(),
    'estimated_wait_minutes': estimatedWaitMinutes,
    'trigger_at': triggerAt.toIso8601String(),
  };

  factory _PendingTicketAlert.fromJson(Map<String, dynamic> json) {
    return _PendingTicketAlert(
      ticketId: (json['ticket_id'] ?? '').toString(),
      ticketNum: (json['ticket_num'] ?? '').toString(),
      createdAt: DateTime.parse((json['created_at'] ?? '').toString()),
      estimatedWaitMinutes:
          int.tryParse((json['estimated_wait_minutes'] ?? '').toString()) ?? 5,
      triggerAt: DateTime.parse((json['trigger_at'] ?? '').toString()),
    );
  }
}
