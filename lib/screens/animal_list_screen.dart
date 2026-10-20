import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../models/shelter_query.dart';
import '../state/animal_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AnimalListScreen extends StatefulWidget {
  final Uri uri;
  const AnimalListScreen({super.key, required this.uri});
  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}
class _AnimalListScreenState extends State<AnimalListScreen> {
  final search = TextEditingController();
  Timer? timer;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      final n = context.read<AnimalNotifier>();
      final p = widget.uri.queryParameters;
      search.text = p['search'] ?? '';
      n.applyQuery(ShelterQuery(
        search: p['search'] ?? '', species: p['species'], status: p['status'],
        minAge: int.tryParse(p['minAge'] ?? ''), maxAge: int.tryParse(p['maxAge'] ?? ''),
        sortField: p['sort']?.split(',').first ?? 'name',
        sortAscending: !(p['sort']?.endsWith(',desc') ?? false),
        page: int.tryParse(p['page'] ?? '') ?? 1,
        size: int.tryParse(p['size'] ?? '') ?? 10,
        includeDeleted: p['deleted'] == 'true',
      ));
    }
  }
  @override
  void dispose() { timer?.cancel(); search.dispose(); super.dispose(); }
  void update(ShelterQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.species != null) params['species'] = q.species!;
    if (q.status != null) params['status'] = q.status!;
    if (q.minAge != null) params['minAge'] = '${q.minAge}';
    if (q.maxAge != null) params['maxAge'] = '${q.maxAge}';
    params['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
    params['page'] = '${q.page}'; params['size'] = '${q.size}';
    if (q.includeDeleted) params['deleted'] = 'true';
    context.go(Uri(path: '/animals', queryParameters: params).toString());
    context.read<AnimalNotifier>().applyQuery(q);
  }
  @override
  Widget build(BuildContext context) => Consumer<AnimalNotifier>(builder: (context, n, _) => ShelterScaffold(
    title: 'Наши питомцы',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Поиск по имени, породе или виду'),
          onChanged: (v) { timer?.cancel(); timer = Timer(const Duration(milliseconds: 350), () => update(n.query.copyWith(search: v))); })),
        const SizedBox(width: 12),
        FilledButton.icon(onPressed: () => context.go('/animals/0'), icon: const Icon(Icons.add), label: const Text('Добавить')),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        DropdownButton<String?>(value: n.query.species, hint: const Text('Все виды'), items: [const DropdownMenuItem(value: null, child: Text('Все виды')), ...['Кошка','Собака'].map((x) => DropdownMenuItem(value: x, child: Text(x)))], onChanged: (v) => update(n.query.copyWith(species: v))),
        DropdownButton<String?>(value: n.query.status, hint: const Text('Любой статус'), items: [const DropdownMenuItem(value: null, child: Text('Любой статус')), ...['Ищет дом','На лечении','На передержке'].map((x) => DropdownMenuItem(value: x, child: Text(x)))], onChanged: (v) => update(n.query.copyWith(status: v))),
        OutlinedButton.icon(onPressed: () => update(n.query.copyWith(includeDeleted: !n.query.includeDeleted)), icon: Icon(n.query.includeDeleted ? Icons.visibility_off : Icons.visibility), label: Text(n.query.includeDeleted ? 'Скрыть удалённых' : 'Показать удалённых')),
        if (n.selected.isNotEmpty) FilledButton.tonalIcon(onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Удалить выбранных?'), content: Text('Будет отмечено: ${n.selected.length}'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить'))]));
          if (ok == true) n.deleteSelected();
        }, icon: const Icon(Icons.delete_outline), label: Text('Удалить выбранных (${n.selected.length})')),
      ]),
      const SizedBox(height: 12),
      if (n.status == LoadStatus.loading) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (n.status == LoadStatus.error) Expanded(child: _Message(icon: Icons.error_outline, title: 'Не удалось загрузить данные', message: n.error ?? 'Неизвестная ошибка', action: () => n.load()))
      else if (n.result.items.isEmpty) const Expanded(child: _Message(icon: Icons.pets, title: 'Никого не нашли', message: 'Измените поисковый запрос или фильтры.'))
      else Expanded(child: LayoutBuilder(builder: (context, c) => c.maxWidth < 600
        ? ListView(children: n.result.items.map((a) => _AnimalCard(a, n)).toList())
        : SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: c.maxWidth), child: DataTable(
          sortColumnIndex: {'name':0,'species':1,'age':2,'status':3}[n.query.sortField], sortAscending: n.query.sortAscending,
          columns: [
            const DataColumn(label: Text('Выбор')),
            DataColumn(label: const Text('Имя'), onSort: (_,__) => update(n.query.copyWith(sortField: 'name', sortAscending: n.query.sortField == 'name' ? !n.query.sortAscending : true))),
            DataColumn(label: const Text('Вид'), onSort: (_,__) => update(n.query.copyWith(sortField: 'species', sortAscending: n.query.sortField == 'species' ? !n.query.sortAscending : true))),
            DataColumn(label: const Text('Возраст'), numeric: true, onSort: (_,__) => update(n.query.copyWith(sortField: 'age', sortAscending: n.query.sortField == 'age' ? !n.query.sortAscending : true))),
            DataColumn(label: const Text('Статус'), onSort: (_,__) => update(n.query.copyWith(sortField: 'status', sortAscending: n.query.sortField == 'status' ? !n.query.sortAscending : true))),
            const DataColumn(label: Text('Действия')),
          ],
          rows: n.result.items.map((a) => DataRow(selected: n.selected.contains(a.id), cells: [
            DataCell(Checkbox(value: n.selected.contains(a.id), onChanged: (_) => n.toggleSelection(a.id))),
            DataCell(Text(a.name), onTap: () => context.go('/animals/${a.id}')),
            DataCell(Text(a.species)), DataCell(Text('${a.age}')), DataCell(Text(a.status)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Открыть', onPressed: () => context.go('/animals/${a.id}'), icon: const Icon(Icons.open_in_new)),
              if (a.isDeleted) IconButton(tooltip: 'Восстановить', onPressed: () => n.restore(a.id), icon: const Icon(Icons.restore))
              else IconButton(tooltip: 'Удалить', onPressed: () => n.softDelete(a.id), icon: const Icon(Icons.delete_outline)),
              IconButton(tooltip: 'Удалить навсегда', onPressed: () => n.hardDelete(a.id), icon: const Icon(Icons.delete_forever_outlined)),
            ])),
          ])).toList(),
        )))),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('Всего: ${n.result.total}'),
        const SizedBox(width: 12),
        DropdownButton<int>(value: n.query.size, items: [10,25,50].map((x) => DropdownMenuItem(value: x, child: Text('$x / стр.'))).toList(), onChanged: (v) { if (v != null) update(n.query.copyWith(size: v)); }),
        IconButton(tooltip: 'Первая', onPressed: n.query.page > 1 ? () => update(n.query.copyWith(page: 1)) : null, icon: const Icon(Icons.first_page)),
        IconButton(tooltip: 'Предыдущая', onPressed: n.result.hasPrevious ? () => update(n.query.copyWith(page: n.query.page - 1)) : null, icon: const Icon(Icons.chevron_left)),
        Text('${n.result.page} / ${n.result.totalPages}'),
        IconButton(tooltip: 'Следующая', onPressed: n.result.hasNext ? () => update(n.query.copyWith(page: n.query.page + 1)) : null, icon: const Icon(Icons.chevron_right)),
        IconButton(tooltip: 'Последняя', onPressed: n.result.hasNext ? () => update(n.query.copyWith(page: n.result.totalPages)) : null, icon: const Icon(Icons.last_page)),
      ]),
    ]),
  ));
}
class _AnimalCard extends StatelessWidget {
  final Animal a; final AnimalNotifier n;
  const _AnimalCard(this.a, this.n);
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFFF6DCE7), child: Icon(a.species == 'Кошка' ? Icons.pets : Icons.cruelty_free, color: const Color(0xFFB85C83))),
    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('${a.species} • ${a.breed} • ${a.age} лет\n${a.status}'),
    isThreeLine: true, onTap: () => context.go('/animals/${a.id}'),
    trailing: Checkbox(value: n.selected.contains(a.id), onChanged: (_) => n.toggleSelection(a.id)),
  ));
}
class _Message extends StatelessWidget {
  final IconData icon; final String title; final String message; final VoidCallback? action;
  const _Message({required this.icon, required this.title, required this.message, this.action});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 52, color: const Color(0xFFB85C83)), const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), Text(message, textAlign: TextAlign.center),
    if (action != null) ...[const SizedBox(height: 12), FilledButton(onPressed: action, child: const Text('Повторить'))],
  ]));
}
