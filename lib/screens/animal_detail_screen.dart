import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/adopter.dart';
import '../models/adoption_request.dart';
import '../models/animal.dart';
import '../models/medical_card.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import '../repositories/adopter_repository.dart';
import '../repositories/animal_repository.dart';
import '../repositories/medical_card_repository.dart';
import '../state/adoption_request_notifier.dart';
import '../state/animal_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AnimalDetailScreen extends StatefulWidget {
  final int id;

  const AnimalDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<AnimalDetailScreen> createState() =>
      _AnimalDetailScreenState();
}

class _AnimalDetailScreenState
    extends State<AnimalDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final breed = TextEditingController();
  final age = TextEditingController();
  final description = TextEditingController();
  final passportNumber = TextEditingController();
  final microchipNumber = TextEditingController();
  final vaccinationNotes = TextEditingController();
  final allergies = TextEditingController();

  String species = 'Кошка';
  String sex = 'Самка';
  String status = 'Ищет дом';
  int? selectedAdopterId;

  bool loaded = false;
  bool saving = false;

  Future<PageResult<Adopter>>? adoptersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      loaded = true;

      adoptersFuture = context
          .read<AdopterRepository>()
          .find(const ShelterQuery(size: 100));

      if (widget.id != 0) {
        _load();
      }
    }
  }

  Future<void> _load() async {
    final animal = await context
        .read<AnimalRepository>()
        .findById(widget.id);

    if (animal == null || !mounted) return;

    name.text = animal.name;
    breed.text = animal.breed;
    age.text = '${animal.age}';
    description.text = animal.description;

    setState(() {
      species = animal.species;
      sex = animal.sex;
      status = animal.status;
    });

    final card = await context
        .read<MedicalCardRepository>()
        .findByAnimalId(widget.id);

    if (!mounted) return;

    passportNumber.text = card.passportNumber;
    microchipNumber.text = card.microchipNumber;
    vaccinationNotes.text = card.vaccinationNotes;
    allergies.text = card.allergies;
  }

  @override
  void dispose() {
    name.dispose();
    breed.dispose();
    age.dispose();
    description.dispose();
    passportNumber.dispose();
    microchipNumber.dispose();
    vaccinationNotes.dispose();
    allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || saving) {
      return;
    }

    setState(() => saving = true);

    try {
      final animal = Animal(
        id: widget.id,
        name: name.text.trim(),
        species: species,
        breed: breed.text.trim(),
        age: int.parse(age.text.trim()),
        sex: sex,
        status: status,
        description: description.text.trim(),
      );

      final savedAnimal = await context
          .read<AnimalNotifier>()
          .save(animal);

      await context.read<MedicalCardRepository>().save(
            MedicalCard(
              animalId: savedAnimal.id,
              passportNumber: passportNumber.text.trim(),
              microchipNumber: microchipNumber.text.trim(),
              vaccinationNotes:
                  vaccinationNotes.text.trim(),
              allergies: allergies.text.trim(),
            ),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Данные питомца и веткарточка сохранены',
          ),
        ),
      );

      context.go('/animals/${savedAnimal.id}');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _createRequest() async {
    final adopterId = selectedAdopterId;

    if (widget.id == 0 || adopterId == null) return;

    try {
      await context
          .read<AdoptionRequestNotifier>()
          .createRequest(
            animalId: widget.id,
            adopterId: adopterId,
          );

      if (!mounted) return;

      setState(() => selectedAdopterId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заявка на пристройство создана'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _changeRequestStatus(
    AdoptionRequest request,
    String newStatus,
  ) async {
    try {
      await context
          .read<AdoptionRequestNotifier>()
          .changeStatus(request, newStatus);

      await context.read<AnimalNotifier>().load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: widget.id == 0
          ? 'Новый питомец'
          : 'Карточка питомца',
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Информация о подопечном',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Имя питомца',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Укажите имя питомца'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: species,
                    decoration: const InputDecoration(
                      labelText: 'Вид',
                    ),
                    items: ['Кошка', 'Собака']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => species = value ?? species,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: breed,
                    decoration: const InputDecoration(
                      labelText: 'Порода',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Возраст (лет)',
                    ),
                    validator: (value) {
                      final parsed =
                          int.tryParse(value ?? '');

                      if (parsed == null ||
                          parsed < 0 ||
                          parsed > 50) {
                        return 'Введите возраст от 0 до 50';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sex,
                    decoration: const InputDecoration(
                      labelText: 'Пол',
                    ),
                    items: ['Самка', 'Самец']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => sex = value ?? sex,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                    ),
                    items: [
                      'Ищет дом',
                      'На лечении',
                      'На передержке',
                      'Пристроен',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => status = value ?? status,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                    ),
                  ),
                  if (widget.id != 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        '/animals/${widget.id}/medical',
                      ),
                      icon: const Icon(
                        Icons.medical_services_outlined,
                      ),
                      label: const Text(
                        'Открыть ветеринарную карточку',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    'Ветеринарная карточка',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Связь один-к-одному: у каждого питомца одна веткарточка.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passportNumber,
                    decoration: const InputDecoration(
                      labelText: 'Номер ветпаспорта',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: microchipNumber,
                    decoration: const InputDecoration(
                      labelText: 'Номер микрочипа',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vaccinationNotes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Прививки и процедуры',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: allergies,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Аллергии / примечания',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      saving
                          ? 'Сохранение...'
                          : 'Сохранить питомца и веткарточку',
                    ),
                  ),
                  if (widget.id != 0) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const Text(
                      'Заявки на пристройство',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Один человек может подать заявки на разных животных, '
                      'а на одного питомца могут претендовать разные люди.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<PageResult<Adopter>>(
                      future: adoptersFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        final adopters = snapshot.data!.items;

                        if (adopters.isEmpty) {
                          return const Text(
                            'Сначала добавьте потенциального хозяина.',
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedAdopterId,
                                decoration: const InputDecoration(
                                  labelText: 'Потенциальный хозяин',
                                ),
                                items: adopters
                                    .map(
                                      (adopter) =>
                                          DropdownMenuItem<int>(
                                        value: adopter.id,
                                        child: Text(adopter.fullName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(
                                  () => selectedAdopterId = value,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: selectedAdopterId == null
                                  ? null
                                  : _createRequest,
                              child: const Text('Создать заявку'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Consumer<AdoptionRequestNotifier>(
                      builder: (context, notifier, _) {
                        final requests =
                            notifier.forAnimal(widget.id);

                        if (notifier.isLoading && requests.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (notifier.error != null &&
                            requests.isEmpty) {
                          return Text(notifier.error!);
                        }

                        if (requests.isEmpty) {
                          return const Text(
                            'Заявок на этого питомца пока нет.',
                          );
                        }

                        return Column(
                          children: requests
                              .map(
                                (request) =>
                                    _requestCard(context, request),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeRequest(
    AdoptionRequest request,
  ) async {
    try {
      await context
          .read<AdoptionRequestNotifier>()
          .remove(request);

      await context.read<AnimalNotifier>().load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  Widget _requestCard(
    BuildContext context,
    AdoptionRequest request,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Adopter?>(
          future: context
              .read<AdopterRepository>()
              .findById(request.adopterId),
          builder: (context, snapshot) {
            final adopter = snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adopter?.fullName ??
                      (snapshot.connectionState ==
                              ConnectionState.waiting
                          ? 'Загрузка хозяина...'
                          : 'Потенциальный хозяин #${request.adopterId}'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(request.note),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: request.status,
                        isExpanded: true,
                        items: AdoptionRequest.statuses
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _changeRequestStatus(request, value);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Удалить заявку',
                      onPressed: () => _removeRequest(request),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}