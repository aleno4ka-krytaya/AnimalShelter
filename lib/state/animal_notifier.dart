import 'package:flutter/foundation.dart';
import '../models/animal.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import '../repositories/animal_repository.dart';

enum LoadStatus { idle, loading, success, error }

class AnimalNotifier extends ChangeNotifier {
  final AnimalRepository repository;
  AnimalNotifier(this.repository);
  ShelterQuery _query = const ShelterQuery();
  PageResult<Animal> _result = PageResult<Animal>(items: [], page: 1, size: 10, total: 0);
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  ShelterQuery get query => _query;
  PageResult<Animal> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);

  Future<void> load() async {
    _status = LoadStatus.loading; _error = null; notifyListeners();
    try { _result = await repository.find(_query); _status = LoadStatus.success; }
    catch (e) { _error = 'Не удалось загрузить питомцев: $e'; _status = LoadStatus.error; }
    notifyListeners();
  }
  Future<void> applyQuery(ShelterQuery q) async { _query = q; _selected.clear(); await load(); }
  void toggleSelection(int id) { _selected.contains(id) ? _selected.remove(id) : _selected.add(id); notifyListeners(); }
  Future<void> deleteSelected() async { await repository.deleteMany(_selected.toList()); _selected.clear(); await load(); }
  Future<void> softDelete(int id) async { await repository.softDelete(id); await load(); }
  Future<void> hardDelete(int id) async { await repository.hardDelete(id); await load(); }
  Future<void> restore(int id) async { await repository.restore(id); await load(); }
  Future<void> save(Animal a) async { if (a.id == 0) { await repository.create(a); } else { await repository.update(a); } await load(); }
}
