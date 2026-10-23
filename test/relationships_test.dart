import 'package:flutter_test/flutter_test.dart';

import 'package:animal_shelter/models/adoption_request.dart';
import 'package:animal_shelter/models/medical_card.dart';

import 'package:animal_shelter/repositories/adoption_request_repository.dart';
import 'package:animal_shelter/repositories/medical_card_repository.dart';

void main() {
  group(
    'Связь «питомец — потенциальный хозяин» через заявки',
    () {
      late InMemoryAdoptionRequestRepository repository;

      setUp(() {
        repository =
            InMemoryAdoptionRequestRepository();
      });

      test(
        'один питомец может иметь заявки от разных людей',
        () async {
          await repository.create(
            animalId: 1,
            adopterId: 3,
          );

          final requests = await repository.findAll();

          final forFirstAnimal = requests
              .where((item) => item.animalId == 1)
              .toList();

          expect(forFirstAnimal.length, 3);

          expect(
            forFirstAnimal
                .map((item) => item.adopterId)
                .toSet()
                .length,
            3,
          );
        },
      );

      test(
        'нельзя создать две активные заявки одной пары',
        () async {
          await expectLater(
            repository.create(
              animalId: 1,
              adopterId: 1,
            ),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'у питомца не может быть двух одобренных заявок',
        () async {
          final newRequest = await repository.create(
            animalId: 1,
            adopterId: 3,
          );

          await repository.update(
            newRequest.copyWith(status: 'Одобрена'),
          );

          final secondRequest =
              await repository.create(
            animalId: 1,
            adopterId: 4,
          );

          await expectLater(
            repository.update(
              secondRequest.copyWith(status: 'Одобрена'),
            ),
            throwsA(isA<StateError>()),
          );
        },
      );
    },
  );

  test(
    'у питомца одна веткарточка, повторное сохранение обновляет её',
    () async {
      final repository = InMemoryMedicalCardRepository();

      await repository.save(
        const MedicalCard(
          animalId: 77,
          passportNumber: 'ВЕТ-77',
        ),
      );

      await repository.save(
        const MedicalCard(
          animalId: 77,
          passportNumber: 'ВЕТ-77-NEW',
          microchipNumber: 'CHIP-77',
        ),
      );

      final card = await repository.findByAnimalId(77);

      expect(card.passportNumber, 'ВЕТ-77-NEW');
      expect(card.microchipNumber, 'CHIP-77');
    },
  );
}