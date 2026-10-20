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
    required this.id, required this.name, required this.species, required this.breed,
    required this.age, required this.sex, required this.status, required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Animal copyWith({
    String? name, String? species, String? breed, int? age, String? sex,
    String? status, String? description, DateTime? deletedAt, bool clearDeletedAt = false,
  }) => Animal(
    id: id, name: name ?? this.name, species: species ?? this.species,
    breed: breed ?? this.breed, age: age ?? this.age, sex: sex ?? this.sex,
    status: status ?? this.status, description: description ?? this.description,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}
