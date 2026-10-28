class Animal {
  final int id;
  final String name;
  final String species;
  final String breed;
  final int age;
  final String sex;
  final String status;
  final String description;
  final DateTime? deletedAt;

  const Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.sex,
    required this.status,
    required this.description,
    this.deletedAt,
  });

  /// Создаёт объект питомца из JSON, полученного от сервера.
  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      species: (json['species'] ?? 'Кошка').toString(),
      breed: (json['breed'] ?? 'Не указана').toString(),
      age: (json['age'] as num?)?.toInt() ?? 0,
      sex: (json['sex'] ?? 'Самка').toString(),
      status: (json['status'] ?? 'Ищет дом').toString(),
      description: (json['description'] ?? '').toString(),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'].toString()),
    );
  }

  /// Преобразует объект питомца в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'sex': sex,
      'status': status,
      'description': description,
    };
  }

  bool get isDeleted => deletedAt != null;

  Animal copyWith({
    String? name,
    String? species,
    String? breed,
    int? age,
    String? sex,
    String? status,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Animal(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      status: status ?? this.status,
      description: description ?? this.description,
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }
}