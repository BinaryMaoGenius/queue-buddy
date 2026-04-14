import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/agence.dart';
import '../models/ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FirebaseService {
  // Access Firebase instances lazily
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Toggle this to switch between real Firebase and Local Mock
  static const bool _useMock = true;

  // --- MOCK DATA LAYER ---
  static final List<Agence> _mockAgences = [
    Agence(id: 'a1', nom: 'Sira Bank - Siège (ACI 2000)', adresse: 'Avenue du Mali, Bamako', ville: 'Bamako', latitude: 12.6392, longitude: -8.0267, enAttenteCount: 2, isOpen: true, peakHours: '08h30 - 10h30'),
    Agence(id: 'a2', nom: 'Sira Bank - Badalabougou', adresse: "Près de l'Ambassade d'Allemagne", ville: 'Bamako', latitude: 12.6186, longitude: -7.9961, enAttenteCount: 0, isOpen: true, peakHours: '14h00 - 16h30'),
    Agence(id: 'a3', nom: 'Sira Bank - Magnambougou', adresse: 'Boulevard de la CEDEAO', ville: 'Bamako', latitude: 12.6072, longitude: -7.9467, enAttenteCount: 5, isOpen: true, peakHours: '10h00 - 12h00'),
  ];

  static final List<GAB> _mockGabs = [
    GAB(id: 'g1', agenceId: 'a1', numero: 1, statut: 'online'),
    GAB(id: 'g2', agenceId: 'a1', numero: 2, statut: 'online'),
    GAB(id: 'g3', agenceId: 'a2', numero: 1, statut: 'maintenance'),
  ];

  static final List<Guichet> _mockGuichets = [
    Guichet(id: 'gu1', agenceId: 'a1', numero: 1, statut: 'open'),
    Guichet(id: 'gu2', agenceId: 'a1', numero: 2, statut: 'open'),
    Guichet(id: 'gu3', agenceId: 'a2', numero: 1, statut: 'closed'),
  ];

  static final List<Ticket> _mockTickets = [
    Ticket(id: 't1', agenceId: 'a1', numeroTicket: 'A-101', clientNom: 'Mamadou Diallo', clientTel: '76001122', typeOperation: 'Versement', statut: 'enAttente', position: 1, createdAt: DateTime.now()),
    Ticket(id: 't2', agenceId: 'a1', numeroTicket: 'A-102', clientNom: 'Awa Traoré', clientTel: '66554433', typeOperation: 'Retrait', statut: 'enAttente', position: 2, createdAt: DateTime.now()),
  ];

  // Stream Controllers for Mock
  static final _agencesController = StreamController<List<Agence>>.broadcast();
  static final _ticketsController = StreamController<List<Ticket>>.broadcast();

  FirebaseService() {
    if (_useMock) {
      _agencesController.add(_mockAgences);
      _ticketsController.add(_mockTickets);
    }
    setupNotifications();
  }

  // Subscribe to all agencies
  Stream<List<Agence>> getAgences() async* {
    if (_useMock) {
      yield List.from(_mockAgences);
      yield* _agencesController.stream;
    } else {
      yield* _db.collection('agences').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => Agence.fromFirestore(doc.id, doc.data())).toList();
      });
    }
  }

  // Subscribe to GABs for an agency
  Stream<List<GAB>> getGabs(String agenceId) async* {
    if (_useMock) {
      yield _mockGabs.where((g) => g.agenceId == agenceId).toList();
      // GAB updates are less frequent in mock, so we can stop here or use a controller
    } else {
      yield* _db
        .collection('gabs')
        .where('agence_id', isEqualTo: agenceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GAB.fromFirestore(doc.id, doc.data())).toList();
    });
    }
  }

  // Subscribe to Guichets for an agency
  Stream<List<Guichet>> getGuichets(String agenceId) async* {
    if (_useMock) {
      yield _mockGuichets.where((g) => g.agenceId == agenceId).toList();
    } else {
      yield* _db
        .collection('guichets')
        .where('agence_id', isEqualTo: agenceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Guichet.fromFirestore(doc.id, doc.data())).toList();
    });
    }
  }

  // Subscribe to a specific ticket
  Stream<Ticket?> getTicket(String ticketId) async* {
    if (_useMock) {
      yield _mockTickets.cast<Ticket?>().firstWhere((t) => t?.id == ticketId, orElse: () => null);
      yield* _ticketsController.stream.map((tickets) {
        try {
          return tickets.firstWhere((t) => t.id == ticketId);
        } catch (_) {
          return null;
        }
      });
    } else {
      yield* _db.collection('tickets').doc(ticketId).snapshots().map((doc) {
        if (doc.exists) {
          return Ticket.fromFirestore(doc.id, doc.data()!);
        }
        return null;
      });
    }
  }

  // Subscribe to all tickets for an agency (ordered by creation)
  Stream<List<Ticket>> getTickets(String agenceId) async* {
    if (_useMock) {
      yield _mockTickets.where((t) => t.agenceId == agenceId).toList();
      yield* _ticketsController.stream.map((tickets) => 
        tickets.where((t) => t.agenceId == agenceId).toList()
      );
    } else {
      yield* _db
          .collection('tickets')
          .where('agence_id', isEqualTo: agenceId)
          .orderBy('created_at', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Ticket.fromFirestore(doc.id, doc.data())).toList();
      });
    }
  }

  // Take a ticket
  Future<Ticket> prendreTicket({
    required String agenceId,
    required String nom,
    required String tel,
    required String operation,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate lag
      
      final int count = _mockTickets.where((t) => t.agenceId == agenceId && t.statut == 'enAttente').length;
      final newTicket = Ticket(
        id: 't${_mockTickets.length + 1}',
        agenceId: agenceId,
        numeroTicket: 'A-${_mockTickets.length + 101}',
        clientNom: nom,
        clientTel: tel,
        typeOperation: operation,
        statut: 'enAttente',
        position: count + 1,
        createdAt: DateTime.now(),
      );
      
      _mockTickets.add(newTicket);
      
      // Save to local history
      await _saveTicketToHistory(newTicket.id);
      
      // Update Agence count
      final agIdx = _mockAgences.indexWhere((a) => a.id == agenceId);
      if (agIdx != -1) {
        _mockAgences[agIdx] = Agence(
          id: _mockAgences[agIdx].id,
          nom: _mockAgences[agIdx].nom,
          adresse: _mockAgences[agIdx].adresse,
          ville: _mockAgences[agIdx].ville,
          latitude: _mockAgences[agIdx].latitude,
          longitude: _mockAgences[agIdx].longitude,
          enAttenteCount: _mockAgences[agIdx].enAttenteCount + 1,
          isOpen: _mockAgences[agIdx].isOpen,
          peakHours: _mockAgences[agIdx].peakHours,
        );
      }

      _ticketsController.add(List.from(_mockTickets));
      _agencesController.add(List.from(_mockAgences));
      return newTicket;
    }

    // Real Firebase logic
    final positionSnap = await _db
        .collection('tickets')
        .where('agence_id', isEqualTo: agenceId)
        .where('statut', isEqualTo: 'enAttente')
        .get();
    final int position = positionSnap.docs.length + 1;

    final totalSnap = await _db
        .collection('tickets')
        .where('agence_id', isEqualTo: agenceId)
        .get();
    final String ticketNum = 'A-${totalSnap.docs.length + 100}';

    final data = {
      'agence_id': agenceId,
      'numero_ticket': ticketNum,
      'client_nom': nom,
      'client_tel': tel,
      'type_operation': operation,
      'statut': 'enAttente',
      'position': position,
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef = await _db.collection('tickets').add(data);
    
    await _saveTicketToHistory(docRef.id);

    await _db.collection('agences').doc(agenceId).update({
      'enAttenteCount': FieldValue.increment(1),
    });

    return Ticket.fromFirestore(docRef.id, data);
  }

  // Call next (Agent action)
  Future<void> appelerSuivant(String agenceId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final nextIdx = _mockTickets.indexWhere((t) => t.agenceId == agenceId && t.statut == 'enAttente');
      if (nextIdx != -1) {
        final ticketId = _mockTickets[nextIdx].id;
        
        // Mark as called
        _mockTickets[nextIdx] = _mockTickets[nextIdx].copyWith(
          statut: 'appele',
          position: 0,
          callTime: DateTime.now(),
        );
        
        // Decrement agency count
        final agIdx = _mockAgences.indexWhere((a) => a.id == agenceId);
        if (agIdx != -1) {
          _mockAgences[agIdx] = _mockAgences[agIdx].copyWith(
            enAttenteCount: _mockAgences[agIdx].enAttenteCount - 1
          );
        }

        // Reorder others
        for (int i = 0; i < _mockTickets.length; i++) {
          if (_mockTickets[i].agenceId == agenceId && _mockTickets[i].statut == 'enAttente' && _mockTickets[i].id != ticketId) {
             _mockTickets[i] = _mockTickets[i].copyWith(position: _mockTickets[i].position - 1);
          }
        }

        _ticketsController.add(List.from(_mockTickets));
        _agencesController.add(List.from(_mockAgences));

        // Simulate Notification
        _simulateNotification(
          "C'est votre tour !",
          "Le ticket ${_mockTickets[nextIdx].numeroTicket} est appelé au guichet."
        );
      }
      return;
    }

    // Real Firebase logic
    final nextSnap = await _db
        .collection('tickets')
        .where('agence_id', isEqualTo: agenceId)
        .where('statut', isEqualTo: 'enAttente')
        .orderBy('created_at', descending: false)
        .limit(1)
        .get();

    if (nextSnap.docs.isNotEmpty) {
      final nextDoc = nextSnap.docs.first;
      
      await _db.runTransaction((transaction) async {
        transaction.update(nextDoc.reference, {
          'statut': 'appele',
          'position': 0,
          'call_time': FieldValue.serverTimestamp(),
        });

        transaction.update(_db.collection('agences').doc(agenceId), {
          'enAttenteCount': FieldValue.increment(-1),
        });

        final otherSnap = await _db
            .collection('tickets')
            .where('agence_id', isEqualTo: agenceId)
            .where('statut', isEqualTo: 'enAttente')
            .get();

        for (var doc in otherSnap.docs) {
          if (doc.id != nextDoc.id) {
            final int currentPos = doc.data()['position'] ?? 0;
            transaction.update(doc.reference, {'position': currentPos - 1});
          }
        }
      });
    }
  }

  // Validate ticket
  Future<void> validerTicket(String ticketId) async {
    if (_useMock) {
      final idx = _mockTickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _mockTickets[idx] = _mockTickets[idx].copyWith(
          statut: 'valide',
          position: 0,
          validationTime: DateTime.now(),
        );
        _ticketsController.add(List.from(_mockTickets));
      }
      return;
    }
    await _db.collection('tickets').doc(ticketId).update({
      'statut': 'valide',
      'position': 0,
      'validation_time': FieldValue.serverTimestamp(),
    });
  }

  // Analytics helper (Aggregates from real data if available)
  Stream<Map<String, dynamic>> getAnalyticsStream(String agenceId) {
    return getTickets(agenceId).map((tickets) {
      // Average Wait Time (Wait = CallTime - CreatedAt)
      double totalWaitMinutes = 0;
      int calledCount = 0;
      Map<int, int> volumeByHour = {};

      for (var t in tickets) {
        // Volume by hour
        int hour = t.createdAt.hour;
        volumeByHour[hour] = (volumeByHour[hour] ?? 0) + 1;

        // Wait time
        if (t.callTime != null) {
          totalWaitMinutes += t.callTime!.difference(t.createdAt).inMinutes;
          calledCount++;
        }
      }

      double avgWait = calledCount > 0 ? totalWaitMinutes / calledCount : 0;

      return {
        'avgWait': avgWait,
        'volumeByHour': volumeByHour,
        'totalToday': tickets.length,
        'processedToday': calledCount,
      };
    });
  }

  // Update Guichet status
  Future<void> updateGuichetStatus(String guichetId, String status) async {
    if (_useMock) {
      final idx = _mockGuichets.indexWhere((g) => g.id == guichetId);
      if (idx != -1) {
        _mockGuichets[idx] = _mockGuichets[idx].copyWith(statut: status);
      }
      return;
    }
    await _db.collection('guichets').doc(guichetId).update({
      'statut': status,
    });
  }

  // --- NOTIFICATION LAYER ---

  Future<void> setupNotifications() async {
    if (kIsWeb) return;
    try {
      // Initialize local notifications for foreground (Always useful)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        linux: initializationSettingsLinux,
      );
      await _localNotifications.initialize(initializationSettings);

      if (_useMock) {
        debugPrint('Mock mode: skipping FCM setup');
        return;
      }

      // Real FCM setup
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }
  }

  Future<void> subscribeToTicketTopic(String ticketId) async {
    if (_useMock) {
      debugPrint('Mock: Subscribed to ticket_$ticketId');
      return;
    }
    
    try {
      await _fcm.subscribeToTopic('ticket_$ticketId');
      debugPrint('Subscribed to topic: ticket_$ticketId');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Simulate sending a notification (Mock only)
  Future<void> _simulateNotification(String title, String body) async {
    if (kIsWeb) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('high_importance_channel', 'High Importance Notifications',
            importance: Importance.max, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(0, title, body, platformChannelSpecifics);
  }

  // --- REVIEW SYSTEM ---
  Future<void> submitReview(String ticketId, int rating, String comment) async {
    if (_useMock) {
      final idx = _mockTickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _mockTickets[idx] = _mockTickets[idx].copyWith(rating: rating, comment: comment);
        _ticketsController.add(List.from(_mockTickets));
      }
      return;
    }
    await _db.collection('tickets').doc(ticketId).update({
      'rating': rating,
      'comment': comment,
    });
  }

  // --- HISTORY SYSTEM ---
  Future<void> _saveTicketToHistory(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('ticket_history') ?? [];
    if (!history.contains(ticketId)) {
      history.insert(0, ticketId);
      await prefs.setStringList('ticket_history', history);
    }
  }

  Future<List<Ticket>> getHistoryTickets() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyIds = prefs.getStringList('ticket_history') ?? [];
    
    if (_useMock) {
      // For mock, we simply filter the mock list by stored IDs
      return _mockTickets.where((t) => historyIds.contains(t.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    List<Ticket> tickets = [];
    for (String id in historyIds) {
      final doc = await _db.collection('tickets').doc(id).get();
      if (doc.exists) {
        tickets.add(Ticket.fromFirestore(doc.id, doc.data()!));
      }
    }
    return tickets;
  }
}
