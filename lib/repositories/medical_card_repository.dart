import '../models/medical_card.dart';

abstract interface class MedicalCardRepository {
  Future<MedicalCard> findByAnimalId(int animalId);

  Future<MedicalCard> save(MedicalCard card);

  Future<void> deleteForAnimal(int animalId);
}

class InMemoryMedicalCardRepository
    implements MedicalCardRepository {
  // Ключ карты — animalId, поэтому у одного питомца
  // не может быть двух карточек.
  final Map<int, MedicalCard> _cards = {
    1: const MedicalCard(
      animalId: 1,
      passportNumber: 'ВЕТ-0001',
      microchipNumber: '643098100001001',
      vaccinationNotes: 'Комплексная вакцинация, 2026 г.',
      allergies: 'Не указаны',
    ),
    2: const MedicalCard(
      animalId: 2,
      passportNumber: 'ВЕТ-0002',
      microchipNumber: '643098100001002',
      vaccinationNotes: 'Плановая вакцинация завершена.',
      allergies: 'Нет известных аллергий',
    ),
  };

  @override
  Future<MedicalCard> findByAnimalId(int animalId) async =>
      _cards[animalId] ?? MedicalCard(animalId: animalId);

  @override
  Future<MedicalCard> save(MedicalCard card) async {
    _cards[card.animalId] = card;
    return card;
  }

  @override
  Future<void> deleteForAnimal(int animalId) async {
    _cards.remove(animalId);
  }
}