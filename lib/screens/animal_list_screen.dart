import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../models/shelter_query.dart';
import '../repositories/medical_card_repository.dart';
import '../state/adoption_request_notifier.dart';
import '../state/animal_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AnimalListScreen extends StatefulWidget {
  final Uri uri;

  const AnimalListScreen({
    super.key,
    required this.uri,
  });

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  final TextEditingController search = TextEditingController();

  Timer? timer;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (initialized) return;
    initialized = true;

    final params = widget.uri.queryParameters;
    search.text = params['search'] ?? '';

    context.read<AnimalNotifier>().applyQuery(
          ShelterQuery(
            search: params['search'] ?? '',
            species: params['species'],
            status: params['status'],
            minAge: int.tryParse(params['minAge'] ?? ''),
            maxAge: int.tryParse(params['maxAge'] ?? ''),
            sortField: params['sort']?.split(',').first ?? 'name',
            sortAscending: !(params['sort']?.endsWith(',desc') ?? false),
            page: int.tryParse(params['page'] ?? '') ?? 1,
            size: int.tryParse(params['size'] ?? '') ?? 10,
            includeDeleted: params['deleted'] == 'true',
          ),
        );
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  void update(ShelterQuery query) {
    final params = <String, String>{
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': '${query.page}',
      'size': '${query.size}',
    };

    if (query.search.isNotEmpty) {
      params['search'] = query.search;
    }

    if (query.species != null) {
      params['species'] = query.species!;
    }

    if (query.status != null) {
      params['status'] = query.status!;
    }

    if (query.minAge != null) {
      params['minAge'] = '${query.minAge}';
    }

    if (query.maxAge != null) {
      params['maxAge'] = '${query.maxAge}';
    }

    if (query.includeDeleted) {
      params['deleted'] = 'true';
    }

    context.go(
      Uri(
        path: '/animals',
        queryParameters: params,
      ).toString(),
    );

    context.read<AnimalNotifier>().applyQuery(query);
  }

  Future<void> _hardDeleteAnimal(
    int id,
    AnimalNotifier notifier,
  ) async {
    final requestNotifier = context.read<AdoptionRequestNotifier>();

    final medicalRepository = context.read<MedicalCardRepository>();

    try {
      // Сначала удаляем связанные заявки и медкарту,
      // затем физически удаляем самого питомца.
      await requestNotifier.removeForAnimal(id);
      await medicalRepository.deleteForAnimal(id);
      await notifier.hardDelete(id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось удалить питомца: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalNotifier>(
      builder: (context, notifier, _) {
        return ShelterScaffold(
          title: 'Наши питомцы',
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
                        labelText: 'Поиск по имени, породе или виду',
                      ),
                      onChanged: (value) {
                        timer?.cancel();

                        timer = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            update(
                              notifier.query.copyWith(
                                search: value,
                                page: 1,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/animals/0'),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String?>(
                    value: notifier.query.species,
                    hint: const Text('Все виды'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все виды'),
                      ),
                      ...['Кошка', 'Собака'].map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      update(
                        notifier.query.copyWith(
                          species: value,
                          page: 1,
                        ),
                      );
                    },
                  ),
                  DropdownButton<String?>(
                    value: notifier.query.status,
                    hint: const Text('Любой статус'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Любой статус'),
                      ),
                      ...[
                        'Ищет дом',
                        'На лечении',
                        'На передержке',
                        'Пристроен',
                      ].map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      update(
                        notifier.query.copyWith(
                          status: value,
                          page: 1,
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      update(
                        notifier.query.copyWith(
                          includeDeleted: !notifier.query.includeDeleted,
                          page: 1,
                        ),
                      );
                    },
                    icon: Icon(
                      notifier.query.includeDeleted
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(
                      notifier.query.includeDeleted
                          ? 'Скрыть удалённых'
                          : 'Показать удалённых',
                    ),
                  ),
                  if (notifier.selected.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: notifier.deleteSelected,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        'Удалить выбранных '
                        '(${notifier.selected.length})',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (notifier.status == LoadStatus.loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (notifier.status == LoadStatus.error)
                Expanded(
                  child: _Message(
                    icon: Icons.error_outline,
                    title: 'Не удалось загрузить данные',
                    message: notifier.error ?? 'Неизвестная ошибка',
                    action: notifier.load,
                  ),
                )
              else if (notifier.result.items.isEmpty)
                const Expanded(
                  child: _Message(
                    icon: Icons.pets,
                    title: 'Никого не нашли',
                    message: 'Измените поисковый запрос или фильтры.',
                  ),
                )
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return ListView(
                          children: notifier.result.items
                              .map(
                                (animal) => _AnimalCard(animal, notifier),
                              )
                              .toList(),
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            sortColumnIndex: <String, int>{
                              'name': 1,
                              'species': 2,
                              'age': 3,
                              'status': 4,
                            }[notifier.query.sortField],
                            sortAscending: notifier.query.sortAscending,
                            columns: [
                              const DataColumn(
                                label: Text('Выбор'),
                              ),
                              DataColumn(
                                label: const Text('Имя'),
                                onSort: (_, __) {
                                  update(
                                    notifier.query.copyWith(
                                      sortField: 'name',
                                      sortAscending:
                                          notifier.query.sortField == 'name'
                                              ? !notifier.query.sortAscending
                                              : true,
                                    ),
                                  );
                                },
                              ),
                              DataColumn(
                                label: const Text('Вид'),
                                onSort: (_, __) {
                                  update(
                                    notifier.query.copyWith(
                                      sortField: 'species',
                                      sortAscending:
                                          notifier.query.sortField == 'species'
                                              ? !notifier.query.sortAscending
                                              : true,
                                    ),
                                  );
                                },
                              ),
                              DataColumn(
                                label: const Text('Возраст'),
                                numeric: true,
                                onSort: (_, __) {
                                  update(
                                    notifier.query.copyWith(
                                      sortField: 'age',
                                      sortAscending:
                                          notifier.query.sortField == 'age'
                                              ? !notifier.query.sortAscending
                                              : true,
                                    ),
                                  );
                                },
                              ),
                              DataColumn(
                                label: const Text('Статус'),
                                onSort: (_, __) {
                                  update(
                                    notifier.query.copyWith(
                                      sortField: 'status',
                                      sortAscending:
                                          notifier.query.sortField == 'status'
                                              ? !notifier.query.sortAscending
                                              : true,
                                    ),
                                  );
                                },
                              ),
                              const DataColumn(
                                label: Text('Действия'),
                              ),
                            ],
                            rows: notifier.result.items.map((animal) {
                              return DataRow(
                                selected: notifier.selected.contains(animal.id),
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value:
                                          notifier.selected.contains(animal.id),
                                      onChanged: (_) {
                                        notifier.toggleSelection(
                                          animal.id,
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    Text(animal.name),
                                    onTap: () {
                                      context.go(
                                        '/animals/${animal.id}',
                                      );
                                    },
                                  ),
                                  DataCell(
                                    Text(animal.species),
                                  ),
                                  DataCell(
                                    Text('${animal.age}'),
                                  ),
                                  DataCell(
                                    Text(animal.status),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Открыть веткарточку.
                                        IconButton(
                                          tooltip: 'Ветеринарная карточка',
                                          onPressed: () {
                                            context.go(
                                              '/animals/${animal.id}/medical',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.medical_services_outlined,
                                          ),
                                        ),

                                        // Открыть питомца.
                                        IconButton(
                                          tooltip: 'Открыть питомца',
                                          onPressed: () {
                                            context.go(
                                              '/animals/${animal.id}',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.open_in_new,
                                          ),
                                        ),

                                        // Восстановить или мягко удалить.
                                        if (animal.isDeleted)
                                          IconButton(
                                            tooltip: 'Восстановить',
                                            onPressed: () {
                                              notifier.restore(
                                                animal.id,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.restore,
                                            ),
                                          )
                                        else
                                          IconButton(
                                            tooltip: 'Удалить',
                                            onPressed: () {
                                              notifier.softDelete(
                                                animal.id,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),

                                        // Физически удалить питомца
                                        // вместе со связанными данными.
                                        IconButton(
                                          tooltip: 'Удалить навсегда',
                                          onPressed: () {
                                            _hardDeleteAnimal(
                                              animal.id,
                                              notifier,
                                            );
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

              // Управление пагинацией.
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 500;
                  final totalPages =
                      (notifier.result.total / notifier.query.size)
                          .ceil()
                          .clamp(1, 999999);
                  final currentPage = notifier.query.page;

                  Future<void> changePage(int page) async {
                    final safePage = page.clamp(1, totalPages);
                    await notifier.applyQuery(
                      notifier.query.copyWith(page: safePage),
                    );
                  }

                  Future<void> changePageSize(int size) async {
                    await notifier.applyQuery(
                      notifier.query.copyWith(page: 1, size: size),
                    );
                  }

                  final pageSizeDropdown = DropdownButton<int>(
                    value: notifier.query.size,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 10,
                        child: Text('10 / стр.'),
                      ),
                      DropdownMenuItem(
                        value: 20,
                        child: Text('20 / стр.'),
                      ),
                      DropdownMenuItem(
                        value: 50,
                        child: Text('50 / стр.'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        changePageSize(value);
                      }
                    },
                  );

                  final pageButtons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Первая страница',
                        visualDensity: VisualDensity.compact,
                        onPressed: currentPage > 1 ? () => changePage(1) : null,
                        icon: const Icon(Icons.first_page),
                      ),
                      IconButton(
                        tooltip: 'Предыдущая страница',
                        visualDensity: VisualDensity.compact,
                        onPressed: currentPage > 1
                            ? () => changePage(currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('$currentPage / $totalPages'),
                      IconButton(
                        tooltip: 'Следующая страница',
                        visualDensity: VisualDensity.compact,
                        onPressed: currentPage < totalPages
                            ? () => changePage(currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      IconButton(
                        tooltip: 'Последняя страница',
                        visualDensity: VisualDensity.compact,
                        onPressed: currentPage < totalPages
                            ? () => changePage(totalPages)
                            : null,
                        icon: const Icon(Icons.last_page),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text('Всего: ${notifier.result.total}'),
                            pageSizeDropdown,
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.center,
                          child: pageButtons,
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Всего: ${notifier.result.total}'),
                      const SizedBox(width: 8),
                      pageSizeDropdown,
                      const SizedBox(width: 8),
                      pageButtons,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Карточка питомца для узкого экрана.
class _AnimalCard extends StatelessWidget {
  final Animal animal;
  final AnimalNotifier notifier;

  const _AnimalCard(this.animal, this.notifier);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF6DCE7),
          child: Icon(
            animal.species == 'Кошка' ? Icons.pets : Icons.cruelty_free,
            color: const Color(0xFFB85C83),
          ),
        ),
        title: Text(
          animal.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${animal.species} • ${animal.breed} • '
          '${animal.age} лет\n${animal.status}',
        ),
        isThreeLine: true,
        onTap: () => context.go('/animals/${animal.id}'),
        trailing: Wrap(
          spacing: 0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Ветеринарная карточка',
              onPressed: () {
                context.go(
                  '/animals/${animal.id}/medical',
                );
              },
              icon: const Icon(
                Icons.medical_services_outlined,
              ),
            ),
            Checkbox(
              value: notifier.selected.contains(animal.id),
              onChanged: (_) {
                notifier.toggleSelection(animal.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Сообщение о загрузке, ошибке или пустом списке.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFFB85C83),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: action,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
