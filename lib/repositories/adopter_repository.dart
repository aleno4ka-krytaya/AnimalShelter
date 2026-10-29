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
  final List<Adopter> _items = List.generate(
    10,
    (i) => Adopter(
      id: i + 1,
      fullName: [
            'Анна Смирнова',
            'Иван Петров',
            'Мария Кузнецова',
            'Алексей Волков',
            'Елена Соколова',
          ][i % 5] +
          (i > 4 ? ' ${i + 1}' : ''),
      city: ['Москва', 'Казань', 'Тула', 'Самара', 'Пермь'][i % 5],
      phone: '+7 900 123-45-${(10 + i).toString()}',
      email: 'user${i + 1}@example.com',
      preferredSpecies: i % 2 == 0 ? 'Кошка' : 'Собака',
    ),
  );

  int _nextId = 11;

  @override
  Future<PageResult<Adopter>> find(ShelterQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));

    var rows = _items.where((a) => q.includeDeleted || !a.isDeleted).toList();
    final n = q.search.trim().toLowerCase();

    if (n.isNotEmpty) {
      rows = rows
          .where(
            (a) =>
                a.fullName.toLowerCase().contains(n) ||
                a.city.toLowerCase().contains(n),
          )
          .toList();
    }

    if (q.species != null) {
      rows = rows.where((a) => a.preferredSpecies == q.species).toList();
    }

    rows.sort((a, b) {
      final c = q.sortField == 'city'
          ? a.city.compareTo(b.city)
          : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      return q.sortAscending ? c : -c;
    });

    final total = rows.length;
    final start = (q.page - 1) * q.size;
    final end = (start + q.size) > total ? total : start + q.size;

    return PageResult(
      items: start >= total ? <Adopter>[] : rows.sublist(start, end),
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Adopter?> findById(int id) async {
    for (final adopter in _items) {
      if (adopter.id == id) {
        return adopter;
      }
    }
    return null;
  }

  @override
  Future<Adopter> create(Adopter adopter) async {
    final value = Adopter(
      id: _nextId++,
      fullName: adopter.fullName,
      city: adopter.city,
      phone: adopter.phone,
      email: adopter.email,
      preferredSpecies: adopter.preferredSpecies,
    );

    _items.add(value);
    return value;
  }

  @override
  Future<Adopter> update(Adopter adopter) async {
    final index = _items.indexWhere((item) => item.id == adopter.id);

    if (index < 0) {
      throw StateError('Кандидат не найден');
    }

    _items[index] = adopter;
    return adopter;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _items.indexWhere((adopter) => adopter.id == id);

    if (index < 0) {
      throw StateError('Кандидат не найден');
    }

    _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((adopter) => adopter.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final index = _items.indexWhere((adopter) => adopter.id == id);

    if (index < 0) {
      throw StateError('Кандидат не найден');
    }

    _items[index] = _items[index].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;

    for (final id in ids) {
      final index = _items.indexWhere(
        (adopter) => adopter.id == id && !adopter.isDeleted,
      );

      if (index != -1) {
        _items[index] = _items[index].copyWith(
          deletedAt: DateTime.now(),
        );
        count++;
      }
    }

    return count;
  }
}
