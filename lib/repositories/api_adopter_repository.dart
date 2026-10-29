import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/adopter.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import 'adopter_repository.dart';

class ApiAdopterRepository implements AdopterRepository {
  final Dio dio;

  ApiAdopterRepository(this.dio);

  Map<String, dynamic> _queryParams(
    ShelterQuery query,
  ) {
    final params = <String, dynamic>{
      'page': query.page,
      'size': query.size,
      'sort': '${query.sortField == 'city' ? 'city' : 'fullName'},'
          '${query.sortAscending ? 'asc' : 'desc'}',
      'includeDeleted': query.includeDeleted,
    };

    if (query.search.trim().isNotEmpty) {
      params['search'] = query.search.trim();
    }

    if (query.species != null) {
      params['species'] = query.species;
    }

    return params;
  }

  @override
  Future<PageResult<Adopter>> find(
    ShelterQuery query,
  ) async {
    final response = await apiRead(
      () => dio.get<dynamic>(
        'adopters',
        queryParameters: _queryParams(query),
      ),
    );

    final data = response.data;

    if (data is! Map || data['items'] is! List) {
      throw const UnexpectedApiException(
        'Сервер вернул неверный формат списка кандидатов.',
      );
    }

    final items = (data['items'] as List)
        .whereType<Map>()
        .map(
          (item) => Adopter.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return PageResult<Adopter>(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? query.page,
      size: (data['size'] as num?)?.toInt() ?? query.size,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }

  @override
  Future<Adopter?> findById(int id) async {
    try {
      final response = await apiRead(
        () => dio.get<dynamic>('adopters/$id'),
      );

      return Adopter.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Adopter> create(Adopter adopter) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'adopters',
        data: adopter.toJson(),
      ),
    );

    return Adopter.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<Adopter> update(Adopter adopter) async {
    final response = await apiRequest(
      () => dio.put<dynamic>(
        'adopters/${adopter.id}',
        data: adopter.toJson(),
      ),
    );

    return Adopter.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<void> softDelete(int id) async {
    await apiRequest(
      () => dio.delete<dynamic>('adopters/$id'),
    );
  }

  @override
  Future<void> hardDelete(int id) async {
    await apiRequest(
      () => dio.delete<dynamic>(
        'adopters/$id',
        queryParameters: {'hard': true},
      ),
    );
  }

  @override
  Future<void> restore(int id) async {
    await apiRequest(
      () => dio.post<dynamic>('adopters/$id/restore'),
    );
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'adopters/bulk-delete',
        data: {'ids': ids},
      ),
    );

    final data = response.data as Map;
    return (data['deleted'] as int?) ?? 0;
  }
}
