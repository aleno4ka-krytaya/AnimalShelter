class Adopter {
  final int id;
  final String fullName;
  final String city;
  final String phone;
  final String email;
  final String preferredSpecies;
  final DateTime? deletedAt;

  const Adopter({
    required this.id,
    required this.fullName,
    required this.city,
    required this.phone,
    required this.email,
    required this.preferredSpecies,
    this.deletedAt,
  });

  /// Создаёт кандидата в усыновители из JSON.
  factory Adopter.fromJson(Map<String, dynamic> json) {
    return Adopter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      preferredSpecies: (json['preferredSpecies'] ?? 'Не важно').toString(),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'].toString()),
    );
  }

  /// Подготавливает данные для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'city': city,
      'phone': phone,
      'email': email,
      'preferredSpecies': preferredSpecies,
    };
  }

  bool get isDeleted => deletedAt != null;

  Adopter copyWith({
    String? fullName,
    String? city,
    String? phone,
    String? email,
    String? preferredSpecies,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Adopter(
      id: id,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      preferredSpecies: preferredSpecies ?? this.preferredSpecies,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
