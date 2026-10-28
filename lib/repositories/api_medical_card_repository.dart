import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/medical_card.dart';
import 'medical_card_repository.dart';

class ApiMedicalCardRepository
    implements MedicalCardRepository {
  final Dio dio;

  ApiMedicalCardRepository(this.dio);

  @override
  Future<MedicalCard> findByAnimalId(int animalId) async {
    final response = await apiRead(
      () => dio.get<dynamic>('medical-cards/$animalId'),
    );

    return MedicalCard.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<MedicalCard> save(MedicalCard card) async {
    final response = await apiRequest(
      () => dio.put<dynamic>(
        'medical-cards/${card.animalId}',
        data: card.toJson(),
      ),
    );

    return MedicalCard.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> deleteForAnimal(int animalId) async {
    await apiRequest(
      () => dio.delete<dynamic>('medical-cards/$animalId'),
    );
  }
}