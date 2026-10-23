/// Ветеринарная карточка связана с одним питомцем по animalId.
/// Для каждого animalId хранится не более одной карточки.
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

  MedicalCard copyWith({
    String? passportNumber,
    String? microchipNumber,
    String? vaccinationNotes,
    String? allergies,
  }) =>
      MedicalCard(
        animalId: animalId,
        passportNumber: passportNumber ?? this.passportNumber,
        microchipNumber: microchipNumber ?? this.microchipNumber,
        vaccinationNotes:
            vaccinationNotes ?? this.vaccinationNotes,
        allergies: allergies ?? this.allergies,
      );
}