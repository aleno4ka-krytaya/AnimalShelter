class AdoptionRequest {
  static const statuses = <String>[
    'Новая',
    'На рассмотрении',
    'Одобрена',
    'Отклонена',
  ];

  final int id;
  final int animalId;
  final int adopterId;
  final String status;
  final String note;
  final DateTime createdAt;

  const AdoptionRequest({
    required this.id,
    required this.animalId,
    required this.adopterId,
    required this.status,
    required this.createdAt,
    this.note = '',
  });

  AdoptionRequest copyWith({
    String? status,
    String? note,
  }) =>
      AdoptionRequest(
        id: id,
        animalId: animalId,
        adopterId: adopterId,
        status: status ?? this.status,
        createdAt: createdAt,
        note: note ?? this.note,
      );
}