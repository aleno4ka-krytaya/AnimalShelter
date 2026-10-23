import '../models/adoption_request.dart';

abstract interface class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> findAll();

  Future<AdoptionRequest> create({
    required int animalId,
    required int adopterId,
    String note = '',
  });

  Future<AdoptionRequest> update(
    AdoptionRequest request,
  );

  Future<void> delete(int id);
}

class InMemoryAdoptionRequestRepository
    implements AdoptionRequestRepository {
  final List<AdoptionRequest> _items = [
    AdoptionRequest(
      id: 1,
      animalId: 1,
      adopterId: 1,
      status: 'На рассмотрении',
      createdAt: DateTime(2026, 10, 2),
      note: 'Есть опыт ухода за кошками.',
    ),
    AdoptionRequest(
      id: 2,
      animalId: 1,
      adopterId: 2,
      status: 'Новая',
      createdAt: DateTime(2026, 10, 6),
    ),
    AdoptionRequest(
      id: 3,
      animalId: 4,
      adopterId: 2,
      status: 'Одобрена',
      createdAt: DateTime(2026, 10, 8),
      note: 'Условия для содержания проверены.',
    ),
    AdoptionRequest(
      id: 4,
      animalId: 5,
      adopterId: 4,
      status: 'Отклонена',
      createdAt: DateTime(2026, 10, 12),
    ),
  ];

  int _nextId = 5;

  @override
  Future<List<AdoptionRequest>> findAll() async =>
      List.unmodifiable(_items);

  @override
  Future<AdoptionRequest> create({
    required int animalId,
    required int adopterId,
    String note = '',
  }) async {
    final duplicate = _items.any(
      (request) =>
          request.animalId == animalId &&
          request.adopterId == adopterId &&
          request.status != 'Отклонена',
    );

    if (duplicate) {
      throw StateError(
        'Для этого питомца у выбранного человека '
        'уже есть активная заявка.',
      );
    }

    final request = AdoptionRequest(
      id: _nextId++,
      animalId: animalId,
      adopterId: adopterId,
      status: 'Новая',
      createdAt: DateTime.now(),
      note: note,
    );

    _items.add(request);
    return request;
  }

  @override
  Future<AdoptionRequest> update(
    AdoptionRequest request,
  ) async {
    if (!AdoptionRequest.statuses.contains(
      request.status,
    )) {
      throw ArgumentError.value(
        request.status,
        'status',
        'Неизвестный статус заявки',
      );
    }

    if (request.status == 'Одобрена') {
      final anotherApproved = _items.any(
        (item) =>
            item.id != request.id &&
            item.animalId == request.animalId &&
            item.status == 'Одобрена',
      );

      if (anotherApproved) {
        throw StateError(
          'У этого питомца уже есть одобренная заявка.',
        );
      }
    }

    final index = _items.indexWhere(
      (item) => item.id == request.id,
    );

    if (index == -1) {
      throw StateError('Заявка не найдена.');
    }

    _items[index] = request;
    return request;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((item) => item.id == id);
  }
}