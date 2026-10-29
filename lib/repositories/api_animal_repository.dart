import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/animal.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import 'animal_repository.dart';

class ApiAnimalRepository implements AnimalRepository {
  final Dio dio;

  CancelToken? _searchToken;

  ApiAnimalRepository(this.dio);

  Map<String, dynamic> _queryParams(
    ShelterQuery query,
  ) {
    final params = <String, dynamic>{
      'page': query.page,
      'size': query.size,
      'sort': '${query.sortField},'
          '${query.sortAscending ? 'asc' : 'desc'}',
      'includeDeleted': query.includeDeleted,
    };

    if (query.search.trim().isNotEmpty) {
      params['search'] = query.search.trim();
    }

    if (query.species != null) {
      params['species'] = query.species;
    }

    if (query.status != null) {
      params['status'] = query.status;
    }

    if (query.minAge != null) {
      params['minAge'] = query.minAge;
    }

    if (query.maxAge != null) {
      params['maxAge'] = query.maxAge;
    }

    return params;
  }

  @override
  Future<PageResult<Animal>> find(
    ShelterQuery query,
  ) async {
    _searchToken?.cancel('Запрос заменён более новым');

    final token = CancelToken();
    _searchToken = token;

    final response = await apiRead(
      () => dio.get<dynamic>(
        'animals',
        queryParameters: _queryParams(query),
        cancelToken: token,
      ),
    );

    final data = response.data;

    if (data is! Map || data['items'] is! List) {
      throw const UnexpectedApiException(
        'Сервер вернул неверный формат списка питомцев.',
      );
    }

    final items = (data['items'] as List)
        .whereType<Map>()
        .map(
          (item) => Animal.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return PageResult<Animal>(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? query.page,
      size: (data['size'] as num?)?.toInt() ?? query.size,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<Animal?> findById(int id) async {
    try {
      final response = await apiRead(
        () => dio.get<dynamic>('animals/$id'),
      );

      return Animal.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Animal> create(Animal animal) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'animals',
        data: animal.toJson(),
      ),
    );

    return Animal.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<Animal> update(Animal animal) async {
    final response = await apiRequest(
      () => dio.put<dynamic>(
        'animals/${animal.id}',
        data: animal.toJson(),
      ),
    );

    return Animal.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await apiRequest(
      () => dio.delete<dynamic>('animals/$id'),
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await apiRequest(
      () => dio.delete<dynamic>(
        'animals/$id',
        queryParameters: {'hard': true},
      ),
    );
  }

  @override
  Future<void> restore(int id) async {
    await apiRequest(
      () => dio.post<dynamic>('animals/$id/restore'),
    );
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'animals/bulk-delete',
        data: {'ids': ids},
      ),
    );

    final data = response.data as Map;
    return (data['deleted'] as int?) ?? 0;
  }
}
