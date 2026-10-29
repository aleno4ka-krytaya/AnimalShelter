import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import 'animal_repository.dart';

class SupabaseAnimalRepository implements AnimalRepository {
  final SupabaseClient client;

  SupabaseAnimalRepository(this.client);

  static const _selectColumns = '''
    *,
    species(name),
    breeds(name)
  ''';

  String _toDatabaseStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'ждет дом':
      case 'ждёт дом':
      case 'ждет семью':
      case 'ждёт семью':
        return 'available';

      case 'на передержке':
        return 'reserved';

      case 'пристроен':
      case 'уже дома':
        return 'adopted';

      case 'на лечении':
        return 'under_treatment';

      case 'недоступен':
        return 'unavailable';

      case 'available':
      case 'reserved':
      case 'adopted':
      case 'under_treatment':
      case 'unavailable':
        return value.trim().toLowerCase();

      default:
        throw ArgumentError('Неизвестный статус животного: $value');
    }
  }

  String _fromDatabaseStatus(String value) {
    switch (value) {
      case 'available':
        return 'Ждёт дом';
      case 'reserved':
        return 'На передержке';
      case 'adopted':
        return 'Пристроен';
      case 'under_treatment':
        return 'На лечении';
      case 'unavailable':
        return 'Недоступен';
      default:
        return value;
    }
  }

  String _toDatabaseSex(String value) {
    switch (value.trim().toLowerCase()) {
      case 'самка':
      case 'женский':
      case 'female':
        return 'female';

      case 'самец':
      case 'мужской':
      case 'male':
        return 'male';

      case 'неизвестно':
      case 'не указан':
      case 'unknown':
      case '':
        return 'unknown';

      default:
        throw ArgumentError('Неизвестный пол животного: $value');
    }
  }

  String _fromDatabaseSex(String value) {
    switch (value) {
      case 'female':
        return 'Самка';
      case 'male':
        return 'Самец';
      default:
        return 'Не указан';
    }
  }

  Map<String, dynamic>? _relation(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }

    return null;
  }

  Animal _fromRow(Map<String, dynamic> row) {
    final speciesRow = _relation(row['species']);
    final breedRow = _relation(row['breeds']);

    final deletedValue = row['deleted_at'];

    return Animal(
      id: (row['id'] as num).toInt(),
      name: (row['name'] ?? '').toString(),
      species: (speciesRow?['name'] ?? '').toString(),
      breed: (breedRow?['name'] ?? '').toString(),
      age: (row['age_years'] as num?)?.round() ?? 0,
      sex: _fromDatabaseSex(
        (row['sex'] ?? 'unknown').toString(),
      ),
      status: _fromDatabaseStatus(
        (row['status'] ?? 'available').toString(),
      ),
      description: (row['description'] ?? '').toString(),
      deletedAt: deletedValue == null
          ? null
          : DateTime.tryParse(deletedValue.toString()),
    );
  }

  Future<int> _getOrCreateSpecies(String name) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('Необходимо указать вид животного.');
    }

    final existing = await client
        .from('species')
        .select('id')
        .eq('name', normalized)
        .maybeSingle();

    if (existing != null) {
      return (existing['id'] as num).toInt();
    }

    final created = await client
        .from('species')
        .insert({'name': normalized})
        .select('id')
        .single();

    return (created['id'] as num).toInt();
  }

  Future<int?> _getOrCreateBreed(
    String name,
    int speciesId,
  ) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      return null;
    }

    final existing = await client
        .from('breeds')
        .select('id')
        .eq('species_id', speciesId)
        .eq('name', normalized)
        .maybeSingle();

    if (existing != null) {
      return (existing['id'] as num).toInt();
    }

    final created = await client
        .from('breeds')
        .insert({
          'species_id': speciesId,
          'name': normalized,
        })
        .select('id')
        .single();

    return (created['id'] as num).toInt();
  }

  Future<Map<String, dynamic>> _toDatabase(
    Animal animal,
  ) async {
    final speciesId = await _getOrCreateSpecies(animal.species);
    final breedId = await _getOrCreateBreed(
      animal.breed,
      speciesId,
    );

    return {
      'name': animal.name.trim(),
      'species_id': speciesId,
      'breed_id': breedId,
      'age_years': animal.age,
      'sex': _toDatabaseSex(animal.sex),
      'status': _toDatabaseStatus(animal.status),
      'description': animal.description.trim(),
    };
  }

  @override
  Future<PageResult<Animal>> find(ShelterQuery query) async {
    final search = query.search.trim();
    final start = (query.page - 1) * query.size;
    final end = start + query.size - 1;

    var request = client.from('animals').select(_selectColumns);

    if (!query.includeDeleted) {
      request = request.eq('is_deleted', false);
    }

    if (search.isNotEmpty) {
      request = request.ilike('name', '%$search%');
    }

    if (query.species != null && query.species!.isNotEmpty) {
      request = request.eq('species.name', query.species!);
    }

    if (query.status != null && query.status!.isNotEmpty) {
      request = request.eq(
        'status',
        _toDatabaseStatus(query.status!),
      );
    }

    if (query.minAge != null) {
      request = request.gte('age_years', query.minAge!);
    }

    if (query.maxAge != null) {
      request = request.lte('age_years', query.maxAge!);
    }

    final sortColumn = switch (query.sortField) {
      'age' => 'age_years',
      'species' => 'name',
      'status' => 'status',
      _ => 'name',
    };

    final response = await request
        .order(sortColumn, ascending: query.sortAscending)
        .range(start, end)
        .count(CountOption.exact);

    final items = response.data
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList();

    return PageResult<Animal>(
      items: items,
      page: query.page,
      size: query.size,
      total: response.count,
    );
  }

  @override
  Future<Animal?> findById(int id) async {
    final row = await client
        .from('animals')
        .select(_selectColumns)
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Animal> create(Animal animal) async {
    final values = await _toDatabase(animal);

    final row = await client
        .from('animals')
        .insert(values)
        .select(_selectColumns)
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Animal> update(Animal animal) async {
    final values = await _toDatabase(animal);

    final row = await client
        .from('animals')
        .update(values)
        .eq('id', animal.id)
        .select(_selectColumns)
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> softDelete(int id) async {
    await client.from('animals').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> hardDelete(int id) async {
    await client.from('animals').delete().eq('id', id);
  }

  @override
  Future<void> restore(int id) async {
    await client.from('animals').update({
      'is_deleted': false,
      'deleted_at': null,
    }).eq('id', id);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) {
      return 0;
    }

    final response = await client
        .from('animals')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .inFilter('id', ids)
        .eq('is_deleted', false)
        .select('id');

    return response.length;
  }
}
