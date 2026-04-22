class GAB {
  final String id;
  final String agenceId;
  final int numero;
  final String statut;

  const GAB({
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

  GAB copyWith({String? agenceId, int? numero, String? statut}) {
    return GAB(
      id: id,
      agenceId: agenceId ?? this.agenceId,
      numero: numero ?? this.numero,
      statut: statut ?? this.statut,
    );
  }
}
