import 'dart:async';
import '../state/animal_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/adopter.dart';
import '../models/shelter_query.dart';
import '../state/adopter_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AdopterListScreen extends StatefulWidget {
  final Uri uri;

  const AdopterListScreen({
    super.key,
    required this.uri,
  });

  @override
  State<AdopterListScreen> createState() => _AdopterListScreenState();
}

class _AdopterListScreenState extends State<AdopterListScreen> {
  final TextEditingController search = TextEditingController();

  Timer? timer;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      initialized = true;

      final p = widget.uri.queryParameters;
      search.text = p['search'] ?? '';

      context.read<AdopterNotifier>().applyQuery(
            ShelterQuery(
              search: p['search'] ?? '',
              species: p['species'],
              sortField: p['sort']?.split(',').first ?? 'name',
              sortAscending: !(p['sort']?.endsWith(',desc') ?? false),
              page: int.tryParse(p['page'] ?? '') ?? 1,
              size: int.tryParse(p['size'] ?? '') ?? 5,
              includeDeleted: p['deleted'] == 'true',
            ),
          );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  void update(ShelterQuery q) {
    final p = <String, String>{
      'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
      'page': '${q.page}',
      'size': '${q.size}',
    };

    if (q.search.isNotEmpty) {
      p['search'] = q.search;
    }

    if (q.species != null) {
      p['species'] = q.species!;
    }

    if (q.includeDeleted) {
      p['deleted'] = 'true';
    }

    context.go(
      Uri(path: '/adopters', queryParameters: p).toString(),
    );

    context.read<AdopterNotifier>().applyQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdopterNotifier>(
      builder: (context, n, _) {
        return ShelterScaffold(
          title: 'Будущие хозяева',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Поиск по имени или городу',
                      ),
                      onChanged: (v) {
                        timer?.cancel();

                        timer = Timer(
                          const Duration(milliseconds: 350),
                          () => update(
                            n.query.copyWith(
                              search: v,
                              page: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/adopters/0'),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  DropdownButton<String?>(
                    value: n.query.species,
                    hint: const Text('Любой питомец'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Любой питомец'),
                      ),
                      ...['Кошка', 'Собака'].map(
                        (x) => DropdownMenuItem<String?>(
                          value: x,
                          child: Text(x),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      update(
                        n.query.copyWith(
                          species: v,
                          page: 1,
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      update(
                        n.query.copyWith(
                          includeDeleted: !n.query.includeDeleted,
                          page: 1,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: Text(
                      n.query.includeDeleted
                          ? 'Скрыть удалённых'
                          : 'Показать удалённых',
                    ),
                  ),
                  if (n.selected.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: () => n.deleteSelected(),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        'Удалить выбранных (${n.selected.length})',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (n.status == LoadStatus.loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (n.status == LoadStatus.error)
                Expanded(
                  child: Center(
                    child: Text(n.error ?? 'Ошибка загрузки'),
                  ),
                )
              else if (n.result.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'По вашему запросу ничего не найдено',
                    ),
                  ),
                )
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth < 600) {
                        return ListView(
                          children: n.result.items
                              .map((a) => _AdopterCard(a, n))
                              .toList(),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: c.maxWidth,
                          ),
                          child: DataTable(
                            columns: [
                              const DataColumn(
                                label: Text('Выбор'),
                              ),
                              DataColumn(
                                label: const Text('ФИО'),
                                onSort: (_, __) {
                                  update(
                                    n.query.copyWith(
                                      sortField: 'name',
                                      sortAscending: n.query.sortField == 'name'
                                          ? !n.query.sortAscending
                                          : true,
                                    ),
                                  );
                                },
                              ),
                              DataColumn(
                                label: const Text('Город'),
                                onSort: (_, __) {
                                  update(
                                    n.query.copyWith(
                                      sortField: 'city',
                                      sortAscending: n.query.sortField == 'city'
                                          ? !n.query.sortAscending
                                          : true,
                                    ),
                                  );
                                },
                              ),
                              const DataColumn(
                                label: Text('Телефон'),
                              ),
                              const DataColumn(
                                label: Text('Email'),
                              ),
                              const DataColumn(
                                label: Text('Предпочтение'),
                              ),
                              const DataColumn(
                                label: Text('Действия'),
                              ),
                            ],
                            rows: n.result.items.map((a) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: n.selected.contains(a.id),
                                      onChanged: (_) {
                                        n.toggleSelection(a.id);
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    Text(a.fullName),
                                    onTap: () {
                                      context.go('/adopters/${a.id}');
                                    },
                                  ),
                                  DataCell(Text(a.city)),
                                  DataCell(Text(a.phone)),
                                  DataCell(Text(a.email)),
                                  DataCell(Text(a.preferredSpecies)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            context.go(
                                              '/adopters/${a.id}',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.open_in_new,
                                          ),
                                        ),
                                        if (a.isDeleted)
                                          IconButton(
                                            onPressed: () {
                                              n.restore(a.id);
                                            },
                                            icon: const Icon(
                                              Icons.restore,
                                            ),
                                          )
                                        else
                                          IconButton(
                                            onPressed: () {
                                              n.softDelete(a.id);
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            n.hardDelete(a.id);
                                          },
                                          icon: const Icon(
                                            Icons.delete_forever_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Всего: ${n.result.total}'),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: n.query.size,
                    items: [5, 10, 25, 50]
                        .map(
                          (x) => DropdownMenuItem<int>(
                            value: x,
                            child: Text('$x / стр.'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        update(
                          n.query.copyWith(
                            size: v,
                            page: 1,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    onPressed: n.query.page > 1
                        ? () {
                            update(
                              n.query.copyWith(page: 1),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.first_page),
                    tooltip: 'Первая страница',
                  ),
                  IconButton(
                    onPressed: n.result.hasPrevious
                        ? () {
                            update(
                              n.query.copyWith(
                                page: n.query.page - 1,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Предыдущая страница',
                  ),
                  Text(
                    '${n.result.page} / ${n.result.totalPages}',
                  ),
                  IconButton(
                    onPressed: n.result.hasNext
                        ? () {
                            update(
                              n.query.copyWith(
                                page: n.query.page + 1,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Следующая страница',
                  ),
                  IconButton(
                    onPressed: n.result.hasNext
                        ? () {
                            update(
                              n.query.copyWith(
                                page: n.result.totalPages,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.last_page),
                    tooltip: 'Последняя страница',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdopterCard extends StatelessWidget {
  final Adopter a;
  final AdopterNotifier n;

  const _AdopterCard(this.a, this.n);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF6DCE7),
          child: Icon(
            Icons.favorite,
            color: Color(0xFFB85C83),
          ),
        ),
        title: Text(a.fullName),
        subtitle: Text(
          '${a.city} • ${a.phone}\n${a.preferredSpecies}',
        ),
        isThreeLine: true,
        onTap: () => context.go('/adopters/${a.id}'),
        trailing: Checkbox(
          value: n.selected.contains(a.id),
          onChanged: (_) => n.toggleSelection(a.id),
        ),
      ),
    );
  }
}
