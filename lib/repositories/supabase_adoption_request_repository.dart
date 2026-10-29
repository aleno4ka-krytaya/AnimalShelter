import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/adoption_request.dart';
import 'adoption_request_repository.dart';

class SupabaseAdoptionRequestRepository implements AdoptionRequestRepository {
  final SupabaseClient client;

  SupabaseAdoptionRequestRepository(this.client);

  String _toDatabaseStatus(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'pending' ||
        normalized.contains('рассмотр') ||
        normalized.contains('новая')) {
      return 'pending';
    }

    if (normalized == 'approved' || normalized.contains('одобр')) {
      return 'approved';
    }

    if (normalized == 'rejected' || normalized.contains('отклон')) {
      return 'rejected';
    }

    if (normalized == 'withdrawn' || normalized.contains('отоз')) {
      return 'withdrawn';
    }

    if (normalized == 'completed' || normalized.contains('заверш')) {
      return 'completed';
    }

    throw ArgumentError('Неизвестный статус заявки: $value');
  }

  String _fromDatabaseStatus(String value) {
    switch (value) {
      case 'pending':
        return 'На рассмотрении';
      case 'approved':
        return 'Одобрена';
      case 'rejected':
        return 'Отклонена';
      case 'withdrawn':
        return 'Отозвана';
      case 'completed':
        return 'Завершена';
      default:
        return value;
    }
  }

  AdoptionRequest _fromRow(Map<String, dynamic> row) {
    return AdoptionRequest(
      id: (row['id'] as num).toInt(),
      animalId: (row['animal_id'] as num).toInt(),
      adopterId: (row['adopter_id'] as num?)?.toInt() ?? 0,
      status: _fromDatabaseStatus(
        (row['status'] ?? 'pending').toString(),
      ),
      createdAt: DateTime.parse(row['created_at'].toString()),
      note: (row['message'] ?? '').toString(),
    );
  }

  @override
  Future<List<AdoptionRequest>> findAll() async {
    final rows = await client
        .from('adoption_requests')
        .select()
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => _fromRow(
            Map<String, dynamic>.from(row),
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
    final currentUserId = client.auth.currentUser?.id;

    final row = await client
        .from('adoption_requests')
        .insert({
          'animal_id': animalId,
          'adopter_id': adopterId,
          'applicant_user_id': currentUserId,
          'status': 'pending',
          'message': note.trim(),
        })
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<AdoptionRequest> update(
    AdoptionRequest request,
  ) async {
    final row = await client
        .from('adoption_requests')
        .update({
          'animal_id': request.animalId,
          'adopter_id': request.adopterId,
          'status': _toDatabaseStatus(request.status),
          'message': request.note.trim(),
        })
        .eq('id', request.id)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> delete(int id) async {
    await client.from('adoption_requests').delete().eq('id', id);
  }
}
