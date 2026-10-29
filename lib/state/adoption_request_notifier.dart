import 'package:flutter/foundation.dart';

import '../models/adoption_request.dart';
import '../repositories/adoption_request_repository.dart';
import '../repositories/animal_repository.dart';

class AdoptionRequestNotifier extends ChangeNotifier {
  final AdoptionRequestRepository repository;
  final AnimalRepository animalRepository;

  AdoptionRequestNotifier(
    this.repository,
    this.animalRepository,
  );

  List<AdoptionRequest> _items = const [];
  bool _isLoading = false;
  String? _error;

  List<AdoptionRequest> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<AdoptionRequest> forAnimal(int animalId) {
    final result = _items.where((item) => item.animalId == animalId).toList();

    result.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return result;
  }

  List<AdoptionRequest> forAdopter(int adopterId) {
    final result = _items.where((item) => item.adopterId == adopterId).toList();

    result.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return result;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await repository.findAll();
    } catch (e) {
      _error = 'Не удалось загрузить заявки: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRequest({
    required int animalId,
    required int adopterId,
    String note = '',
  }) async {
    await repository.create(
      animalId: animalId,
      adopterId: adopterId,
      note: note,
    );

    await load();
  }

  Future<void> changeStatus(
    AdoptionRequest request,
    String status,
  ) async {
    await repository.update(
      request.copyWith(status: status),
    );

    await _synchronizeAnimalStatus(request.animalId);
    await load();
  }

  Future<void> remove(
    AdoptionRequest request,
  ) async {
    await repository.delete(request.id);
    await _synchronizeAnimalStatus(request.animalId);
    await load();
  }

  Future<void> removeForAnimal(int animalId) async {
    await load();

    final related = forAnimal(animalId);

    for (final request in related) {
      await repository.delete(request.id);
    }

    await load();
  }

  Future<void> removeForAdopter(int adopterId) async {
    await load();

    final related = forAdopter(adopterId);

    final affectedAnimalIds =
        related.map((request) => request.animalId).toSet();

    for (final request in related) {
      await repository.delete(request.id);
    }

    for (final animalId in affectedAnimalIds) {
      await _synchronizeAnimalStatus(animalId);
    }

    await load();
  }

  Future<void> _synchronizeAnimalStatus(
    int animalId,
  ) async {
    _items = await repository.findAll();

    final animal = await animalRepository.findById(animalId);

    if (animal == null) return;

    final hasApprovedRequest = _items.any(
      (request) => request.animalId == animalId && request.status == 'Одобрена',
    );

    if (hasApprovedRequest && animal.status != 'Пристроен') {
      await animalRepository.update(
        animal.copyWith(status: 'Пристроен'),
      );
    } else if (!hasApprovedRequest && animal.status == 'Пристроен') {
      await animalRepository.update(
        animal.copyWith(status: 'Ищет дом'),
      );
    }
  }
}
