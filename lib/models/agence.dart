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

  Agence copyWith({int? enAttenteCount, bool? isOpen, String? peakHours}) {
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
