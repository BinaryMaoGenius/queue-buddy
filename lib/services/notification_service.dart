import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import 'package:audioplayers/audioplayers.dart';

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

/// Manages in-app notifications and smart alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final _controller = StreamController<List<AppNotification>>.broadcast();
  Timer? _timer30;
  Timer? _timer10;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Premium Sound URLs
  static const String _soundSuccess = "https://cdn.pixabay.com/audio/2022/03/15/audio_73147814b7.mp3"; // Success ping
  static const String _soundReminder = "https://cdn.pixabay.com/audio/2021/08/04/audio_062123992b.mp3"; // Gentle alert
  static const String _soundYourTurn = "https://cdn.pixabay.com/audio/2022/11/04/audio_32c25603ca.mp3"; // Bell/Announcement

  Stream<List<AppNotification>> get notificationStream => _controller.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Called when a ticket is successfully taken
  void onTicketTaken(String ticketId, String ticketNum) {
    _addNotification(
      title: AppStrings.notifTicketTaken,
      body: "${AppStrings.notifTicketTakenBody} ($ticketNum)",
      type: 'ticket_taken',
    );

    // Schedule smart alerts (simulated timing for demo)
    _scheduleSmartAlerts(ticketId, ticketNum);
  }

  /// Schedule 30-min and 10-min alerts (using shorter intervals for demo purposes)
  void _scheduleSmartAlerts(String ticketId, String ticketNum) {
    // Cancel previous timers
    _timer30?.cancel();
    _timer10?.cancel();

    // In a real app, these would be based on estimated wait time
    // For demo: 30s => "30 min reminder", 50s => "10 min reminder"
    _timer30 = Timer(const Duration(seconds: 30), () {
      _addNotification(
        title: AppStrings.notif30min,
        body: AppStrings.notif30minBody,
        type: '30min',
      );
    });

    _timer10 = Timer(const Duration(seconds: 50), () {
      _addNotification(
        title: AppStrings.notif10min,
        body: AppStrings.notif10minBody,
        type: '10min',
      );
    });
  }

  /// Called when it's the client's turn
  void onYourTurn(String ticketNum) {
    _addNotification(
      title: AppStrings.notifYourTurn,
      body: "${AppStrings.notifYourTurnBody} ($ticketNum)",
      type: 'your_turn',
    );
  }

  void _addNotification({required String title, required String body, required String type}) {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, notif);
    _controller.add(List.from(_notifications));
    _playSound(type);
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

  void markAllRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _controller.add(List.from(_notifications));
  }

  void clearAll() {
    _notifications.clear();
    _controller.add(List.from(_notifications));
  }

  void dispose() {
    _timer30?.cancel();
    _timer10?.cancel();
    _controller.close();
  }
}
