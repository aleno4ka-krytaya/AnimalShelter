import '../models/adopter.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';

abstract interface class AdopterRepository {
  Future<PageResult<Adopter>> find(ShelterQuery query);
  Future<Adopter?> findById(int id);
  Future<Adopter> create(Adopter adopter);
  Future<Adopter> update(Adopter adopter);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}

class InMemoryAdopterRepository implements AdopterRepository {
  final List<Adopter> _items = List.generate(10, (i) => Adopter(
    id: i + 1,
    fullName: ['Анна Смирнова','Иван Петров','Мария Кузнецова','Алексей Волков','Елена Соколова'][i % 5] + (i > 4 ? ' ${i + 1}' : ''),
    city: ['Москва','Казань','Тула','Самара','Пермь'][i % 5],
    phone: '+7 900 123-45-${(10 + i).toString()}',
    email: 'user${i + 1}@example.com',
    preferredSpecies: i % 2 == 0 ? 'Кошка' : 'Собака',
  ));
  int _nextId = 11;

  @override
  Future<PageResult<Adopter>> find(ShelterQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var rows = _items.where((a) => q.includeDeleted || !a.isDeleted).toList();
    final n = q.search.trim().toLowerCase();
    if (n.isNotEmpty) rows = rows.where((a) => a.fullName.toLowerCase().contains(n) || a.city.toLowerCase().contains(n)).toList();
    if (q.species != null) rows = rows.where((a) => a.preferredSpecies == q.species).toList();
    rows.sort((a,b) {
      final c = q.sortField == 'city' ? a.city.compareTo(b.city) : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      return q.sortAscending ? c : -c;
    });
    final total = rows.length, start = (q.page - 1) * q.size;
    final end = (start + q.size) > total ? total : start + q.size;
    return PageResult(items: start >= total ? <Adopter>[] : rows.sublist(start, end), page: q.page, size: q.size, total: total);
  }
  @override
  Future<Adopter?> findById(int id) async {
    for (final a in _items) { if (a.id == id) return a; } return null;
  }
  @override
  Future<Adopter> create(Adopter a) async {
    final v = Adopter(id: _nextId++, fullName: a.fullName, city: a.city, phone: a.phone, email: a.email, preferredSpecies: a.preferredSpecies);
    _items.add(v); return v;
  }
  @override
  Future<Adopter> update(Adopter a) async {
    final i = _items.indexWhere((x) => x.id == a.id);
    if (i < 0) throw StateError('Кандидат не найден');
    _items[i] = a; return a;
  }
  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) throw StateError('Кандидат не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
  }
  @override
  Future<void> hardDelete(int id) async => _items.removeWhere((a) => a.id == id);
  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) throw StateError('Кандидат не найден');
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
