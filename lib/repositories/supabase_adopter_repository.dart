import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adopter.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import 'adopter_repository.dart';

class SupabaseAdopterRepository implements AdopterRepository {
  final SupabaseClient client;

  SupabaseAdopterRepository(this.client);

  Adopter _fromRow(Map<String, dynamic> row) {
    final deletedAt = row['deleted_at'];

    return Adopter(
      id: (row['id'] as num).toInt(),
      fullName: (row['full_name'] ?? '').toString(),
      city: (row['city'] ?? '').toString(),
      phone: (row['phone'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      preferredSpecies: (row['preferred_species'] ?? '').toString(),
      deletedAt:
          deletedAt == null ? null : DateTime.tryParse(deletedAt.toString()),
    );
  }

  Map<String, dynamic> _toRow(Adopter adopter) {
    return {
      'full_name': adopter.fullName.trim(),
      'city': adopter.city.trim(),
      'phone': adopter.phone.trim(),
      'email': adopter.email.trim(),
      'preferred_species': adopter.preferredSpecies.trim(),
    };
  }

  @override
  Future<PageResult<Adopter>> find(ShelterQuery query) async {
    final search = query.search.trim();
    final start = (query.page - 1) * query.size;
    final end = start + query.size - 1;

    var request = client.from('adopters').select();

    if (!query.includeDeleted) {
      request = request.eq('is_deleted', false);
    }

    if (search.isNotEmpty) {
      request = request.or(
        'full_name.ilike.%$search%,city.ilike.%$search%',
      );
    }

    if (query.species != null && query.species!.isNotEmpty) {
      request = request.eq(
        'preferred_species',
        query.species!,
      );
    }

    final sortColumn = query.sortField == 'city' ? 'city' : 'full_name';

    final response = await request
        .order(sortColumn, ascending: query.sortAscending)
        .range(start, end)
        .count(CountOption.exact);

    final items = response.data
        .map(
          (row) => _fromRow(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

    return PageResult<Adopter>(
      items: items,
      page: query.page,
      size: query.size,
      total: response.count,
    );
  }

  @override
  Future<Adopter?> findById(int id) async {
    final row =
        await client.from('adopters').select().eq('id', id).maybeSingle();

    if (row == null) {
      return null;
    }

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Adopter> create(Adopter adopter) async {
    final row =
        await client.from('adopters').insert(_toRow(adopter)).select().single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<Adopter> update(Adopter adopter) async {
    final row = await client
        .from('adopters')
        .update(_toRow(adopter))
        .eq('id', adopter.id)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> softDelete(int id) async {
    await client.from('adopters').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> hardDelete(int id) async {
    await client.from('adopters').delete().eq('id', id);
  }

  @override
  Future<void> restore(int id) async {
    await client.from('adopters').update({
      'is_deleted': false,
      'deleted_at': null,
    }).eq('id', id);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) {
      return 0;
    }

    final rows = await client
        .from('adopters')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .inFilter('id', ids)
        .eq('is_deleted', false)
        .select('id');

    return rows.length;
  }
}
