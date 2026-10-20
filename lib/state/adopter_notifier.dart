import 'package:flutter/foundation.dart';
import '../models/adopter.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import '../repositories/adopter_repository.dart';
import 'animal_notifier.dart';

class AdopterNotifier extends ChangeNotifier {
  final AdopterRepository repository;
  AdopterNotifier(this.repository);
  ShelterQuery _query = const ShelterQuery();
  PageResult<Adopter> _result = PageResult<Adopter>(items: [], page: 1, size: 10, total: 0);
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  ShelterQuery get query => _query;
  PageResult<Adopter> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  Future<void> load() async {
    _status = LoadStatus.loading; _error = null; notifyListeners();
    try { _result = await repository.find(_query); _status = LoadStatus.success; }
    catch (e) { _error = 'Не удалось загрузить список людей: $e'; _status = LoadStatus.error; }
    notifyListeners();
  }
  Future<void> applyQuery(ShelterQuery q) async { _query = q; _selected.clear(); await load(); }
  void toggleSelection(int id) { _selected.contains(id) ? _selected.remove(id) : _selected.add(id); notifyListeners(); }
  Future<void> deleteSelected() async { await repository.deleteMany(_selected.toList()); _selected.clear(); await load(); }
  Future<void> softDelete(int id) async { await repository.softDelete(id); await load(); }
  Future<void> hardDelete(int id) async { await repository.hardDelete(id); await load(); }
  Future<void> restore(int id) async { await repository.restore(id); await load(); }
  Future<void> save(Adopter a) async { if (a.id == 0) { await repository.create(a); } else { await repository.update(a); } await load(); }
}
