
import 'package:flutter_test/flutter_test.dart';

import 'package:animal_shelter/models/animal.dart';
import 'package:animal_shelter/models/adoption_request.dart';
import 'package:animal_shelter/models/medical_card.dart';
import 'package:animal_shelter/models/app_user.dart';

void main() {
  group('Модульные тесты моделей и ролей', () {
    test('1. Animal корректно разбирает JSON', () {
      final animal = Animal.fromJson({
        'id': 7,
        'name': 'Барсик',
        'species': 'Кошка',
        'breed': 'Домашняя',
        'age': 3,
        'sex': 'Самец',
        'status': 'Ищет дом',
        'description': 'Спокойный кот',
      });

      expect(animal.id, 7);
      expect(animal.name, 'Барсик');
      expect(animal.age, 3);
      expect(animal.description, 'Спокойный кот');
    });

    test('2. Animal определяет удалённую запись', () {
      final animal = Animal.fromJson({
        'id': 1,
        'name': 'Мурка',
        'deletedAt': '2026-01-15T10:00:00.000Z',
      });

      expect(animal.isDeleted, isTrue);
      expect(animal.deletedAt, isNotNull);
    });

    test('3. AdoptionRequest разбирает JSON', () {
      final request = AdoptionRequest.fromJson({
        'id': 5,
        'animalId': 7,
        'adopterId': 3,
        'status': 'Новая',
        'note': 'Готовы забрать',
        'createdAt': '2026-01-15T10:00:00.000Z',
      });

      expect(request.id, 5);
      expect(request.animalId, 7);
      expect(request.adopterId, 3);
      expect(request.note, 'Готовы забрать');
    });

    test('4. MedicalCard разбирает медицинские данные', () {
      final card = MedicalCard.fromJson({
        'animalId': 7,
        'passportNumber': 'VET-123',
        'microchipNumber': 'CHIP-456',
        'vaccinationNotes': 'Вакцинация выполнена',
        'allergies': 'Нет',
      });

      expect(card.animalId, 7);
      expect(card.passportNumber, 'VET-123');
      expect(card.microchipNumber, 'CHIP-456');
      expect(card.allergies, 'Нет');
    });

    test('5. AppUser разбирает роль администратора', () {
      final user = AppUser.fromJson({
        'id': 1,
        'username': 'admin',
        'fullName': 'Администратор',
        'email': 'admin@example.com',
        'role': 'admin',
      });

      expect(user.role, UserRole.admin);
      expect(user.role.level, 2);
    });

    test('6. Неизвестная роль преобразуется в visitor', () {
      expect(UserRole.fromValue('unknown'), UserRole.visitor);
      expect(UserRole.fromValue(null), UserRole.visitor);
    });

    test('7. Администратор имеет права уровня staff', () {
      expect(
        UserRole.admin.hasAtLeast(UserRole.staff),
        isTrue,
      );
      expect(
        UserRole.admin.hasAtLeast(UserRole.admin),
        isTrue,
      );
    });

    test('8. Visitor не имеет прав уровня staff', () {
      expect(
        UserRole.visitor.hasAtLeast(UserRole.staff),
        isFalse,
      );
      expect(
        UserRole.visitor.hasAtLeast(UserRole.admin),
        isFalse,
      );
    });
  });
}
