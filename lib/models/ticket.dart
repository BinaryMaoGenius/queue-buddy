import 'package:cloud_firestore/cloud_firestore.dart';
import 'client.dart';

class Ticket {
  final String id;
  final String agenceId;
  final String agenceNom;
  final String numeroTicket;
  final Client client;
  final String typeOperation;
  final String statut;
  final int position;
  final DateTime createdAt;
  final DateTime? callTime;
  final DateTime? validationTime;
  final int? rating;
  final String? comment;

  const Ticket({
    required this.id,
    required this.agenceId,
    this.agenceNom = '',
    required this.numeroTicket,
    required this.client,
    required this.typeOperation,
    required this.statut,
    required this.position,
    required this.createdAt,
    this.callTime,
    this.validationTime,
    this.rating,
    this.comment,
  });

  // Backward-compatible getters used by existing UI code.
  String get clientNom => client.nom;
  String get clientTel => client.tel;

  factory Ticket.fromFirestore(String id, Map<String, dynamic> data) {
    final dynamic rawClient = data['client'];

    final Client parsedClient;
    if (rawClient is Map<String, dynamic>) {
      parsedClient = Client.fromMap(rawClient);
    } else if (rawClient is Map) {
      parsedClient = Client.fromMap(Map<String, dynamic>.from(rawClient));
    } else {
      // Legacy ticket schema fallback
      parsedClient = Client(
        id: '',
        nom: (data['client_nom'] ?? '').toString(),
        tel: (data['client_tel'] ?? '').toString(),
      );
    }

    return Ticket(
      id: id,
      agenceId: (data['agence_id'] ?? '').toString(),
      agenceNom: (data['agence_nom'] ?? '').toString(),
      numeroTicket: (data['numero_ticket'] ?? '').toString(),
      client: parsedClient,
      typeOperation: (data['type_operation'] ?? '').toString(),
      statut: (data['statut'] ?? 'enAttente').toString(),
      position: _parseInt(data['position']) ?? 0,
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      callTime: _parseDateTime(data['call_time']),
      validationTime: _parseDateTime(data['validation_time']),
      rating: _parseInt(data['rating']),
      comment: data['comment']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore({bool includeLegacyClientFields = true}) {
    final map = <String, dynamic>{
      'agence_id': agenceId,
      'agence_nom': agenceNom,
      'numero_ticket': numeroTicket,
      'client': client.toEmbeddedMap(),
      'type_operation': typeOperation,
      'statut': statut,
      'position': position,
      'created_at': Timestamp.fromDate(createdAt),
      'call_time': callTime != null ? Timestamp.fromDate(callTime!) : null,
      'validation_time':
          validationTime != null ? Timestamp.fromDate(validationTime!) : null,
      'rating': rating,
      'comment': comment,
    };

    if (includeLegacyClientFields) {
      map['client_nom'] = client.nom;
      map['client_tel'] = client.tel;
    }

    return map;
  }

  Ticket copyWith({
    String? agenceNom,
    String? numeroTicket,
    Client? client,
    String? clientNom, // backward-compatible override
    String? clientTel, // backward-compatible override
    String? typeOperation,
    String? statut,
    int? position,
    DateTime? createdAt,
    DateTime? callTime,
    DateTime? validationTime,
    int? rating,
    String? comment,
  }) {
    final baseClient = client ?? this.client;
    final mergedClient =
        (clientNom != null || clientTel != null)
            ? baseClient.copyWith(nom: clientNom, tel: clientTel)
            : baseClient;

    return Ticket(
      id: id,
      agenceId: agenceId,
      agenceNom: agenceNom ?? this.agenceNom,
      numeroTicket: numeroTicket ?? this.numeroTicket,
      client: mergedClient,
      typeOperation: typeOperation ?? this.typeOperation,
      statut: statut ?? this.statut,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      callTime: callTime ?? this.callTime,
      validationTime: validationTime ?? this.validationTime,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
