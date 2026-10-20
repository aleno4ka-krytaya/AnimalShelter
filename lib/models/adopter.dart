class Adopter {
  final int id;
  final String fullName;
  final String city;
  final String phone;
  final String email;
  final String preferredSpecies;
  final DateTime? deletedAt;

  const Adopter({
    required this.id, required this.fullName, required this.city, required this.phone,
    required this.email, required this.preferredSpecies, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Adopter copyWith({
    String? fullName, String? city, String? phone, String? email,
    String? preferredSpecies, DateTime? deletedAt, bool clearDeletedAt = false,
  }) => Adopter(
    id: id, fullName: fullName ?? this.fullName, city: city ?? this.city,
    phone: phone ?? this.phone, email: email ?? this.email,
    preferredSpecies: preferredSpecies ?? this.preferredSpecies,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}
