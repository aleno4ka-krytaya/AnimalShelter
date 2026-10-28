import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/adoption_request.dart';
import 'adoption_request_repository.dart';

class ApiAdoptionRequestRepository
    implements AdoptionRequestRepository {
  final Dio dio;

  ApiAdoptionRequestRepository(this.dio);

  @override
  Future<List<AdoptionRequest>> findAll() async {
    final response = await apiRead(
      () => dio.get<dynamic>('adoption-requests'),
    );

    if (response.data is! List) {
      throw const UnexpectedApiException(
        'Сервер вернул неверный формат списка заявок.',
      );
    }

    return (response.data as List)
        .whereType<Map>()
        .map(
          (item) => AdoptionRequest.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  @override
  Future<AdoptionRequest> create({
    required int animalId,
    required int adopterId,
    String note = '',
  }) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'adoption-requests',
        data: {
          'animalId': animalId,
          'adopterId': adopterId,
          'note': note,
        },
      ),
    );

    return AdoptionRequest.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<AdoptionRequest> update(
    AdoptionRequest request,
  ) async {
    final response = await apiRequest(
      () => dio.put<dynamic>(
        'adoption-requests/${request.id}',
        data: request.toJson(),
      ),
    );

    return AdoptionRequest.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> delete(int id) async {
    await apiRequest(
      () => dio.delete<dynamic>('adoption-requests/$id'),
    );
  }
}