import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String nom;
  final String tel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.nom,
    required this.tel,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromFirestore(String id, Map<String, dynamic> data) {
    return Client(
      id: id,
      nom: (data['nom'] ?? data['client_nom'] ?? '').toString(),
      tel: (data['tel'] ?? data['client_tel'] ?? '').toString(),
      createdAt: _timestampToDateTime(data['created_at']),
      updatedAt: _timestampToDateTime(data['updated_at']),
    );
  }

  factory Client.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return Client(
      id: id,
      nom: (data['nom'] ?? data['client_nom'] ?? '').toString(),
      tel: (data['tel'] ?? data['client_tel'] ?? '').toString(),
      createdAt: _timestampToDateTime(data['created_at']),
      updatedAt: _timestampToDateTime(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore({bool withServerTimestamps = false}) {
    return {
      'nom': nom,
      'tel': tel,
      if (withServerTimestamps) ...{
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      } else ...{
        if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
      },
    };
  }

  /// Useful when embedding client inside another document (e.g. ticket)
  Map<String, dynamic> toEmbeddedMap() {
    return {'id': id, 'nom': nom, 'tel': tel};
  }

  Client copyWith({
    String? id,
    String? nom,
    String? tel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      tel: tel ?? this.tel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
