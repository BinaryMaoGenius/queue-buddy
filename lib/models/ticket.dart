import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String agenceId;
  final String agenceNom; // Added for convenience in views
  final String numeroTicket;
  final String clientNom;
  final String clientTel;
  final String typeOperation;
  final String statut;
  final int position;
  final DateTime createdAt;
  final DateTime? callTime;
  final DateTime? validationTime;
  final int? rating;
  final String? comment;

  Ticket({
    required this.id,
    required this.agenceId,
    this.agenceNom = '',
    required this.numeroTicket,
    required this.clientNom,
    required this.clientTel,
    required this.typeOperation,
    required this.statut,
    required this.position,
    required this.createdAt,
    this.callTime,
    this.validationTime,
    this.rating,
    this.comment,
  });

  factory Ticket.fromFirestore(String id, Map<String, dynamic> data) {
    return Ticket(
      id: id,
      agenceId: data['agence_id'] ?? '',
      agenceNom: data['agence_nom'] ?? '',
      numeroTicket: data['numero_ticket'] ?? '',
      clientNom: data['client_nom'] ?? '',
      clientTel: data['client_tel'] ?? '',
      typeOperation: data['type_operation'] ?? '',
      statut: data['statut'] ?? 'enAttente',
      position: data['position'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      callTime: (data['call_time'] as Timestamp?)?.toDate(),
      validationTime: (data['validation_time'] as Timestamp?)?.toDate(),
      rating: data['rating'],
      comment: data['comment'],
    );
  }

  Ticket copyWith({
    String? statut,
    int? position,
    DateTime? callTime,
    DateTime? validationTime,
    int? rating,
    String? comment,
  }) {
    return Ticket(
      id: id,
      agenceId: agenceId,
      agenceNom: agenceNom,
      numeroTicket: numeroTicket,
      clientNom: clientNom,
      clientTel: clientTel,
      typeOperation: typeOperation,
      statut: statut ?? this.statut,
      position: position ?? this.position,
      createdAt: createdAt,
      callTime: callTime ?? this.callTime,
      validationTime: validationTime ?? this.validationTime,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }
}
