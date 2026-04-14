class Agence {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final double latitude;
  final double longitude;
  final int enAttenteCount;
  final bool isOpen;
  final String peakHours;

  Agence({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.latitude,
    required this.longitude,
    required this.enAttenteCount,
    required this.isOpen,
    required this.peakHours,
  });

  factory Agence.fromFirestore(String id, Map<String, dynamic> data) {
    return Agence(
      id: id,
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      ville: data['ville'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      enAttenteCount: data['enAttenteCount'] ?? 0,
      isOpen: data['isOpen'] ?? true,
      peakHours: data['peakHours'] ?? '10h-12h',
    );
  }

  Agence copyWith({
    int? enAttenteCount,
    bool? isOpen,
    String? peakHours,
  }) {
    return Agence(
      id: id,
      nom: nom,
      adresse: adresse,
      ville: ville,
      latitude: latitude,
      longitude: longitude,
      enAttenteCount: enAttenteCount ?? this.enAttenteCount,
      isOpen: isOpen ?? this.isOpen,
      peakHours: peakHours ?? this.peakHours,
    );
  }
}

class GAB {
  final String id;
  final String agenceId;
  final int numero;
  final String statut;

  GAB({
    required this.id,
    required this.agenceId,
    required this.numero,
    required this.statut,
  });

  factory GAB.fromFirestore(String id, Map<String, dynamic> data) {
    return GAB(
      id: id,
      agenceId: data['agence_id'] ?? '',
      numero: data['numero'] ?? 0,
      statut: data['statut'] ?? 'offline',
    );
  }
}

class Guichet {
  final String id;
  final String agenceId;
  final int numero;
  final String statut;

  Guichet({
    required this.id,
    required this.agenceId,
    required this.numero,
    required this.statut,
  });

  factory Guichet.fromFirestore(String id, Map<String, dynamic> data) {
    return Guichet(
      id: id,
      agenceId: data['agence_id'] ?? '',
      numero: data['numero'] ?? 0,
      statut: data['statut'] ?? 'closed',
    );
  }

  Guichet copyWith({
    String? statut,
  }) {
    return Guichet(
      id: id,
      agenceId: agenceId,
      numero: numero,
      statut: statut ?? this.statut,
    );
  }
}
