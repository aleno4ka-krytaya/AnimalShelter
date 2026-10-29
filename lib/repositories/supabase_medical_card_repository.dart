import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_card.dart';
import 'medical_card_repository.dart';

class SupabaseMedicalCardRepository implements MedicalCardRepository {
  final SupabaseClient client;

  SupabaseMedicalCardRepository(this.client);

  MedicalCard _fromRow(Map<String, dynamic> row) {
    return MedicalCard(
      animalId: (row['animal_id'] as num).toInt(),
      passportNumber: (row['passport_number'] ?? '').toString(),
      microchipNumber: (row['microchip_number'] ?? '').toString(),
      vaccinationNotes: (row['vaccination_notes'] ?? '').toString(),
      allergies: (row['allergies'] ?? '').toString(),
    );
  }

  Map<String, dynamic> _toRow(MedicalCard card) {
    return {
      'animal_id': card.animalId,
      'passport_number': card.passportNumber.trim(),
      'microchip_number': card.microchipNumber.trim(),
      'vaccination_notes': card.vaccinationNotes.trim(),
      'allergies': card.allergies.trim(),
    };
  }

  @override
  Future<MedicalCard> findByAnimalId(int animalId) async {
    final row = await client
        .from('medical_cards')
        .select()
        .eq('animal_id', animalId)
        .maybeSingle();

    if (row == null) {
      return MedicalCard(animalId: animalId);
    }

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<MedicalCard> save(MedicalCard card) async {
    final row = await client
        .from('medical_cards')
        .upsert(
          _toRow(card),
          onConflict: 'animal_id',
        )
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteForAnimal(int animalId) async {
    await client.from('medical_cards').delete().eq('animal_id', animalId);
  }
}
