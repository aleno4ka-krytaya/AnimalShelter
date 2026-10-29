/// Ветеринарная карточка связана с одним питомцем по animalId.
/// Для одного питомца хранится не более одной карточки.
class MedicalCard {
  final int animalId;
  final String passportNumber;
  final String microchipNumber;
  final String vaccinationNotes;
  final String allergies;

  const MedicalCard({
    required this.animalId,
    this.passportNumber = '',
    this.microchipNumber = '',
    this.vaccinationNotes = '',
    this.allergies = '',
  });

  /// Создаёт медицинскую карточку из JSON.
  factory MedicalCard.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalCard(
      animalId: (json['animalId'] as num?)?.toInt() ?? 0,
      passportNumber: (json['passportNumber'] ?? '').toString(),
      microchipNumber: (json['microchipNumber'] ?? '').toString(),
      vaccinationNotes: (json['vaccinationNotes'] ?? '').toString(),
      allergies: (json['allergies'] ?? '').toString(),
    );
  }

  /// Подготавливает данные медицинской карточки для сервера.
  Map<String, dynamic> toJson() {
    return {
      'passportNumber': passportNumber,
      'microchipNumber': microchipNumber,
      'vaccinationNotes': vaccinationNotes,
      'allergies': allergies,
    };
  }

  MedicalCard copyWith({
    String? passportNumber,
    String? microchipNumber,
    String? vaccinationNotes,
    String? allergies,
  }) {
    return MedicalCard(
      animalId: animalId,
      passportNumber: passportNumber ?? this.passportNumber,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      vaccinationNotes: vaccinationNotes ?? this.vaccinationNotes,
      allergies: allergies ?? this.allergies,
    );
  }
}
