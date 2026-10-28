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

  /// Создаёт заявку на пристройство из JSON.
  factory AdoptionRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdoptionRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      animalId: (json['animalId'] as num?)?.toInt() ?? 0,
      adopterId: (json['adopterId'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'Новая').toString(),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      note: (json['note'] ?? '').toString(),
    );
  }

  /// Преобразует заявку в JSON.
  Map<String, dynamic> toJson() {
    return {
      'animalId': animalId,
      'adopterId': adopterId,
      'status': status,
      'note': note,
    };
  }

  AdoptionRequest copyWith({
    String? status,
    String? note,
  }) {
    return AdoptionRequest(
      id: id,
      animalId: animalId,
      adopterId: adopterId,
      status: status ?? this.status,
      createdAt: createdAt,
      note: note ?? this.note,
    );
  }
}