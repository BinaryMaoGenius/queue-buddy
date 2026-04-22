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

  Guichet copyWith({String? statut}) {
    return Guichet(
      id: id,
      agenceId: agenceId,
      numero: numero,
      statut: statut ?? this.statut,
    );
  }
}
