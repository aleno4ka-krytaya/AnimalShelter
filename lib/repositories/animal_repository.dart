import '../models/animal.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';

abstract interface class AnimalRepository {
  Future<PageResult<Animal>> find(ShelterQuery query);
  Future<Animal?> findById(int id);
  Future<Animal> create(Animal animal);
  Future<Animal> update(Animal animal);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class InMemoryAnimalRepository implements AnimalRepository {
  final List<Animal> _items = List.generate(24, (i) => Animal(
    id: i + 1,
    name: ['Буся','Луна','Барсик','Мила','Ричи','Снежок','Дымка','Тиша'][i % 8] + (i > 7 ? ' ${i + 1}' : ''),
    species: i % 3 == 0 ? 'Собака' : 'Кошка',
    breed: ['Метис','Шпиц','Британская','Дворняжка'][i % 4],
    age: (i % 9) + 1,
    sex: i % 2 == 0 ? 'Самка' : 'Самец',
    status: ['Ищет дом','На лечении','На передержке'][i % 3],
    description: 'Дружелюбный питомец, которому нужен заботливый и ответственный дом.',
  ));
  int _nextId = 25;

  @override
  Future<PageResult<Animal>> find(ShelterQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var rows = _items.where((a) => q.includeDeleted || !a.isDeleted).toList();
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      rows = rows.where((a) => a.name.toLowerCase().contains(needle) ||
        a.breed.toLowerCase().contains(needle) || a.species.toLowerCase().contains(needle)).toList();
    }
    if (q.species != null) rows = rows.where((a) => a.species == q.species).toList();
    if (q.status != null) rows = rows.where((a) => a.status == q.status).toList();
    if (q.minAge != null) rows = rows.where((a) => a.age >= q.minAge!).toList();
    if (q.maxAge != null) rows = rows.where((a) => a.age <= q.maxAge!).toList();
    rows.sort((a,b) {
      final c = switch (q.sortField) {
        'age' => a.age.compareTo(b.age),
        'species' => a.species.compareTo(b.species),
        'status' => a.status.compareTo(b.status),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? c : -c;
    });
    final total = rows.length;
    final start = (q.page - 1) * q.size;
    final end = (start + q.size) > total ? total : start + q.size;
    final items = start >= total ? <Animal>[] : rows.sublist(start, end);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Animal?> findById(int id) async {
    for (final a in _items) { if (a.id == id) return a; }
    return null;
  }

  @override
  Future<Animal> create(Animal a) async {
    final value = Animal(id: _nextId++, name: a.name, species: a.species, breed: a.breed, age: a.age,
      sex: a.sex, status: a.status, description: a.description);
    _items.add(value); return value;
  }

  @override
  Future<Animal> update(Animal a) async {
    final i = _items.indexWhere((x) => x.id == a.id);
    if (i < 0) throw StateError('Питомец ${a.id} не найден');
    _items[i] = a; return a;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) throw StateError('Питомец не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
  }
  @override
  Future<void> hardDelete(int id) async => _items.removeWhere((a) => a.id == id);
  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) throw StateError('Питомец не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
  }
  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) { _items[i] = _items[i].copyWith(deletedAt: DateTime.now()); count++; }
    }
    return count;
  }
}
