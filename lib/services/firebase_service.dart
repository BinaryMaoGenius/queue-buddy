import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agence.dart';
import '../models/client.dart';
import '../models/gab.dart';
import '../models/guichet.dart';
import '../models/ticket.dart';

class FirebaseService {
  void dispose() {
    // Nettoyage si nécessaire (ex: fermer les StreamControllers s'ils n'étaient pas statiques)
  }

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Toggle this to switch between real Firebase and local mock.
  static const bool _useMock = true;

  // --- MOCK DATA LAYER ---
  static final List<Agence> _mockAgences = [
    Agence(
      id: 'a1',
      nom: 'Sira Bank - Siège (ACI 2000)',
      adresse: 'Avenue du Mali, Bamako',
      ville: 'Bamako',
      latitude: 12.6392,
      longitude: -8.0267,
      enAttenteCount: 2,
      isOpen: true,
      peakHours: '08h30 - 10h30',
    ),
    Agence(
      id: 'a2',
      nom: 'Sira Bank - Badalabougou',
      adresse: "Près de l'Ambassade d'Allemagne",
      ville: 'Bamako',
      latitude: 12.6186,
      longitude: -7.9961,
      enAttenteCount: 0,
      isOpen: true,
      peakHours: '14h00 - 16h30',
    ),
    Agence(
      id: 'a3',
      nom: 'Sira Bank - Magnambougou',
      adresse: 'Boulevard de la CEDEAO',
      ville: 'Bamako',
      latitude: 12.6072,
      longitude: -7.9467,
      enAttenteCount: 5,
      isOpen: true,
      peakHours: '10h00 - 12h00',
    ),
  ];

  static final List<GAB> _mockGabs = [
    const GAB(id: 'g1', agenceId: 'a1', numero: 1, statut: 'online'),
    const GAB(id: 'g2', agenceId: 'a1', numero: 2, statut: 'online'),
    const GAB(id: 'g3', agenceId: 'a2', numero: 1, statut: 'maintenance'),
  ];

  static final List<Guichet> _mockGuichets = [
    Guichet(id: 'gu1', agenceId: 'a1', numero: 1, statut: 'open'),
    Guichet(id: 'gu2', agenceId: 'a1', numero: 2, statut: 'open'),
    Guichet(id: 'gu3', agenceId: 'a2', numero: 1, statut: 'closed'),
  ];

  static final List<Ticket> _mockTickets = [
    Ticket(
      id: 't1',
      agenceId: 'a1',
      agenceNom: 'Sira Bank - Siège (ACI 2000)',
      numeroTicket: 'A-101',
      client: const Client(id: 'c1', nom: 'Mamadou Diallo', tel: '76001122'),
      typeOperation: 'Versement',
      statut: 'enAttente',
      position: 1,
      createdAt: DateTime.now(),
    ),
    Ticket(
      id: 't2',
      agenceId: 'a1',
      agenceNom: 'Sira Bank - Siège (ACI 2000)',
      numeroTicket: 'A-102',
      client: const Client(id: 'c2', nom: 'Awa Traoré', tel: '66554433'),
      typeOperation: 'Retrait',
      statut: 'enAttente',
      position: 2,
      createdAt: DateTime.now(),
    ),
  ];

  static final _agencesController = StreamController<List<Agence>>.broadcast();
  static final _ticketsController = StreamController<List<Ticket>>.broadcast();

  FirebaseService() {
    if (_useMock) {
      _agencesController.add(List.from(_mockAgences));
      _ticketsController.add(List.from(_mockTickets));
    }
    setupNotifications();
  }

  // -------------------- PUBLIC STREAMS --------------------

  Stream<List<Agence>> getAgences() async* {
    if (_useMock) {
      yield List.from(_mockAgences);
      yield* _agencesController.stream;
      return;
    }

    yield* _db.collection('agences').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Agence.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<GAB>> getGabs(String agenceId) async* {
    if (_useMock) {
      yield _mockGabs.where((g) => g.agenceId == agenceId).toList();
      return;
    }

    yield* _db
        .collection('gabs')
        .where('agence_id', isEqualTo: agenceId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GAB.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<Guichet>> getGuichets(String agenceId) async* {
    if (_useMock) {
      yield _mockGuichets.where((g) => g.agenceId == agenceId).toList();
      return;
    }

    yield* _db
        .collection('guichets')
        .where('agence_id', isEqualTo: agenceId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Guichet.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<Ticket?> getTicket(String ticketId) async* {
    if (_useMock) {
      Ticket? current;
      try {
        current = _mockTickets.firstWhere((t) => t.id == ticketId);
      } catch (_) {
        current = null;
      }
      yield current;

      yield* _ticketsController.stream.map((tickets) {
        try {
          return tickets.firstWhere((t) => t.id == ticketId);
        } catch (_) {
          return null;
        }
      });
      return;
    }

    yield* _db.collection('tickets').doc(ticketId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Ticket.fromFirestore(doc.id, doc.data()!);
    });
  }

  Stream<List<Ticket>> getTickets(String agenceId) async* {
    if (_useMock) {
      yield _mockTickets.where((t) => t.agenceId == agenceId).toList();
      yield* _ticketsController.stream.map(
        (tickets) => tickets.where((t) => t.agenceId == agenceId).toList(),
      );
      return;
    }

    yield* _db
        .collection('tickets')
        .where('agence_id', isEqualTo: agenceId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Ticket.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  // -------------------- TICKET LIFECYCLE --------------------

  Future<Ticket> prendreTicket({
    required String agenceId,
    required String nom,
    required String tel,
    required String operation,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));

      final agenceIndex = _mockAgences.indexWhere((a) => a.id == agenceId);
      final agenceNom =
          agenceIndex != -1 ? _mockAgences[agenceIndex].nom : 'Agence';

      final waitingCount =
          _mockTickets
              .where((t) => t.agenceId == agenceId && t.statut == 'enAttente')
              .length;

      final nextNumber = _nextMockTicketNumber();
      final client = Client(
        id: 'c${_mockTickets.length + 1}',
        nom: nom,
        tel: tel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newTicket = Ticket(
        id: 't${_mockTickets.length + 1}',
        agenceId: agenceId,
        agenceNom: agenceNom,
        numeroTicket: 'A-$nextNumber',
        client: client,
        typeOperation: operation,
        statut: 'enAttente',
        position: waitingCount + 1,
        createdAt: DateTime.now(),
      );

      _mockTickets.add(newTicket);
      await _saveTicketToHistory(newTicket.id);

      if (agenceIndex != -1) {
        _mockAgences[agenceIndex] = _mockAgences[agenceIndex].copyWith(
          enAttenteCount: _mockAgences[agenceIndex].enAttenteCount + 1,
        );
      }

      _ticketsController.add(List.from(_mockTickets));
      _agencesController.add(List.from(_mockAgences));
      return newTicket;
    }

    final client = await _findOrCreateClient(nom: nom, tel: tel);

    final ticketRef = _db.collection('tickets').doc();
    final agenceRef = _db.collection('agences').doc(agenceId);
    final counterRef = _db.collection('agence_counters').doc(agenceId);

    late Ticket createdTicket;

    await _db.runTransaction((transaction) async {
      final agenceSnap = await transaction.get(agenceRef);
      final counterSnap = await transaction.get(counterRef);

      final agenceData = agenceSnap.data();
      final agenceNom = (agenceData?['nom'] ?? '').toString();

      final counterData = counterSnap.data();
      final lastTicketNumber = _asInt(counterData?['last_ticket_number']);
      final waitingCount = _asInt(counterData?['waiting_count']);

      final nextTicketNumber = lastTicketNumber + 1;
      final nextPosition = waitingCount + 1;

      final now = DateTime.now();

      final ticketData = <String, dynamic>{
        'agence_id': agenceId,
        'agence_nom': agenceNom,
        'numero_ticket': 'A-$nextTicketNumber',
        'client': client.toEmbeddedMap(),
        // legacy fields kept for compatibility with existing readers/rules
        'client_nom': client.nom,
        'client_tel': client.tel,
        'type_operation': operation,
        'statut': 'enAttente',
        'position': nextPosition,
        'created_at': FieldValue.serverTimestamp(),
      };

      transaction.set(ticketRef, ticketData);

      transaction.set(counterRef, {
        'last_ticket_number': nextTicketNumber,
        'waiting_count': nextPosition,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (agenceSnap.exists) {
        transaction.update(agenceRef, {
          'enAttenteCount': FieldValue.increment(1),
        });
      } else {
        transaction.set(agenceRef, {
          'enAttenteCount': 1,
        }, SetOptions(merge: true));
      }

      createdTicket = Ticket(
        id: ticketRef.id,
        agenceId: agenceId,
        agenceNom: agenceNom,
        numeroTicket: 'A-$nextTicketNumber',
        client: client,
        typeOperation: operation,
        statut: 'enAttente',
        position: nextPosition,
        createdAt: now,
      );
    });

    await _saveTicketToHistory(createdTicket.id);
    return createdTicket;
  }

  Future<void> appelerSuivant(String agenceId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));

      final nextIdx = _mockTickets.indexWhere(
        (t) => t.agenceId == agenceId && t.statut == 'enAttente',
      );

      if (nextIdx == -1) return;

      final ticketId = _mockTickets[nextIdx].id;

      _mockTickets[nextIdx] = _mockTickets[nextIdx].copyWith(
        statut: 'appele',
        position: 0,
        callTime: DateTime.now(),
      );

      final agIdx = _mockAgences.indexWhere((a) => a.id == agenceId);
      if (agIdx != -1) {
        _mockAgences[agIdx] = _mockAgences[agIdx].copyWith(
          enAttenteCount: (_mockAgences[agIdx].enAttenteCount - 1).clamp(
            0,
            1 << 30,
          ),
        );
      }

      for (int i = 0; i < _mockTickets.length; i++) {
        if (_mockTickets[i].agenceId == agenceId &&
            _mockTickets[i].statut == 'enAttente' &&
            _mockTickets[i].id != ticketId) {
          _mockTickets[i] = _mockTickets[i].copyWith(
            position: _mockTickets[i].position - 1,
          );
        }
      }

      _ticketsController.add(List.from(_mockTickets));
      _agencesController.add(List.from(_mockAgences));

      await _simulateNotification(
        "C'est votre tour !",
        "Le ticket ${_mockTickets[nextIdx].numeroTicket} est appelé au guichet.",
      );
      return;
    }

    final nextSnap =
        await _db
            .collection('tickets')
            .where('agence_id', isEqualTo: agenceId)
            .where('statut', isEqualTo: 'enAttente')
            .orderBy('created_at', descending: false)
            .limit(1)
            .get();

    if (nextSnap.docs.isEmpty) return;

    final nextDoc = nextSnap.docs.first;
    final agenceRef = _db.collection('agences').doc(agenceId);
    final counterRef = _db.collection('agence_counters').doc(agenceId);

    await _db.runTransaction((transaction) async {
      transaction.update(nextDoc.reference, {
        'statut': 'appele',
        'position': 0,
        'call_time': FieldValue.serverTimestamp(),
      });

      transaction.update(agenceRef, {
        'enAttenteCount': FieldValue.increment(-1),
      });

      final counterSnap = await transaction.get(counterRef);
      final waitingCount = _asInt(counterSnap.data()?['waiting_count']);

      transaction.set(counterRef, {
        'waiting_count': waitingCount > 0 ? waitingCount - 1 : 0,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Rebuild queue positions (ordered) for remaining waiting tickets.
    final waitingSnap =
        await _db
            .collection('tickets')
            .where('agence_id', isEqualTo: agenceId)
            .where('statut', isEqualTo: 'enAttente')
            .orderBy('created_at', descending: false)
            .get();

    final batch = _db.batch();
    for (int i = 0; i < waitingSnap.docs.length; i++) {
      batch.update(waitingSnap.docs[i].reference, {'position': i + 1});
    }
    await batch.commit();
  }

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

  // -------------------- ANALYTICS --------------------

  Stream<Map<String, dynamic>> getAnalyticsStream(String agenceId) {
    return getTickets(agenceId).map((tickets) {
      double totalWaitMinutes = 0;
      int calledCount = 0;
      final Map<int, int> volumeByHour = {};

      // Dynamic estimation per service type (optional enhancement)
      final Map<String, List<int>> waitTimesByService = {};

      for (final t in tickets) {
        final hour = t.createdAt.hour;
        volumeByHour[hour] = (volumeByHour[hour] ?? 0) + 1;

        if (t.callTime != null) {
          final wait = t.callTime!.difference(t.createdAt).inMinutes;
          totalWaitMinutes += wait;
          calledCount++;

          waitTimesByService.putIfAbsent(t.typeOperation, () => []).add(wait);
        }
      }

      final avgWait = calledCount > 0 ? totalWaitMinutes / calledCount : 5.0;

      // Calculate per-service averages
      final Map<String, double> serviceAvgWait = {};
      waitTimesByService.forEach((service, waits) {
        serviceAvgWait[service] = waits.reduce((a, b) => a + b) / waits.length;
      });

      return {
        'avgWait': avgWait,
        'serviceAvgWait': serviceAvgWait,
        'volumeByHour': volumeByHour,
        'totalToday': tickets.length,
        'processedToday': calledCount,
      };
    });
  }

  /// Returns a realistic estimation based on current queue and history.
  double estimateWaitTime(
    List<Ticket> activeTickets,
    int myPosition,
    Map<String, dynamic>? analytics,
  ) {
    if (myPosition <= 0) return 0;

    final avgWait = (analytics?['avgWait'] as num?)?.toDouble() ?? 5.0;

    // Use a factor of current load
    final loadFactor = activeTickets.length > 10 ? 1.2 : 1.0;

    return myPosition * avgWait * loadFactor;
  }

  // -------------------- TERMINALS --------------------

  Future<void> updateGuichetStatus(String guichetId, String status) async {
    if (_useMock) {
      final idx = _mockGuichets.indexWhere((g) => g.id == guichetId);
      if (idx != -1) {
        _mockGuichets[idx] = _mockGuichets[idx].copyWith(statut: status);
      }
      return;
    }

    await _db.collection('guichets').doc(guichetId).update({'statut': status});
  }

  // -------------------- NOTIFICATIONS --------------------

  Future<void> setupNotifications() async {
    if (kIsWeb) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const linuxInit = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        linux: linuxInit,
      );

      await _localNotifications.initialize(initSettings);

      if (_useMock) {
        debugPrint('Mock mode: skipping FCM setup');
        return;
      }

      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

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

  Future<void> _simulateNotification(String title, String body) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(0, title, body, details);
  }

  // -------------------- REVIEW --------------------

  Future<void> submitReview(String ticketId, int rating, String comment) async {
    if (_useMock) {
      final idx = _mockTickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        _mockTickets[idx] = _mockTickets[idx].copyWith(
          rating: rating,
          comment: comment,
        );
        _ticketsController.add(List.from(_mockTickets));
      }
      return;
    }

    await _db.collection('tickets').doc(ticketId).update({
      'rating': rating,
      'comment': comment,
    });
  }

  // -------------------- HISTORY --------------------

  Future<void> _saveTicketToHistory(String ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('ticket_history') ?? [];

    if (!history.contains(ticketId)) {
      history.insert(0, ticketId);
      await prefs.setStringList('ticket_history', history);
    }
  }

  Future<List<Ticket>> getHistoryTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final historyIds = prefs.getStringList('ticket_history') ?? [];

    if (_useMock) {
      return _mockTickets.where((t) => historyIds.contains(t.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final tickets = <Ticket>[];
    for (final id in historyIds) {
      final doc = await _db.collection('tickets').doc(id).get();
      if (doc.exists) {
        tickets.add(Ticket.fromFirestore(doc.id, doc.data()!));
      }
    }
    return tickets;
  }

  // -------------------- CLIENTS --------------------

  Future<Client> _findOrCreateClient({
    required String nom,
    required String tel,
  }) async {
    final normalizedTel = _normalizePhone(tel);

    final existing =
        await _db
            .collection('clients')
            .where('tel', isEqualTo: normalizedTel)
            .limit(1)
            .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      return Client.fromFirestore(doc.id, doc.data());
    }

    final now = DateTime.now();
    final clientRef = _db.collection('clients').doc();
    final clientData = {
      'nom': nom,
      'tel': normalizedTel,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await clientRef.set(clientData);

    return Client(
      id: clientRef.id,
      nom: nom,
      tel: normalizedTel,
      createdAt: now,
      updatedAt: now,
    );
  }

  // -------------------- HELPERS --------------------

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalizePhone(String tel) {
    return tel.replaceAll(RegExp(r'\s+'), '');
  }

  static int _nextMockTicketNumber() {
    final numbers =
        _mockTickets
            .map((t) => int.tryParse(t.numeroTicket.split('-').last) ?? 100)
            .toList();

    if (numbers.isEmpty) return 101;
    numbers.sort();
    return numbers.last + 1;
  }
}
