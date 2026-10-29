import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adopter.dart';
import '../models/animal.dart';
import '../models/page_result.dart';
import '../models/shelter_query.dart';
import '../repositories/adopter_repository.dart';
import '../repositories/animal_repository.dart';
import '../state/adoption_request_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AdoptionRequestFormScreen extends StatefulWidget {
  const AdoptionRequestFormScreen({super.key});

  @override
  State<AdoptionRequestFormScreen> createState() =>
      _AdoptionRequestFormScreenState();
}

class _AdoptionRequestFormScreenState extends State<AdoptionRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  Future<PageResult<Animal>>? _animalsFuture;
  Future<PageResult<Adopter>>? _adoptersFuture;

  int? _selectedAnimalId;
  int? _selectedAdopterId;

  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    _animalsFuture =
        context.read<AnimalRepository>().find(const ShelterQuery(size: 100));

    _adoptersFuture =
        context.read<AdopterRepository>().find(const ShelterQuery(size: 100));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    if (_loading) return;

    if (!_formKey.currentState!.validate()) return;

    final animalId = _selectedAnimalId;
    final adopterId = _selectedAdopterId;

    if (animalId == null || adopterId == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await context.read<AdoptionRequestNotifier>().createRequest(
            animalId: animalId,
            adopterId: adopterId,
            note: _noteController.text.trim(),
          );

      if (!mounted) return;

      setState(() {
        _selectedAnimalId = null;
        _selectedAdopterId = null;
        _noteController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заявка на пристройство создана.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Bad state: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Не удалось создать заявку.' : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: 'Новая заявка на пристройство',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: FutureBuilder<PageResult<Animal>>(
              future: _animalsFuture,
              builder: (context, animalSnapshot) {
                if (animalSnapshot.hasError) {
                  return const _InfoCard(
                    message: 'Не удалось загрузить список питомцев.',
                  );
                }

                if (!animalSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final animals = animalSnapshot.data!.items
                    .where((animal) => animal.status != 'Пристроен')
                    .toList();

                return FutureBuilder<PageResult<Adopter>>(
                  future: _adoptersFuture,
                  builder: (context, adopterSnapshot) {
                    if (adopterSnapshot.hasError) {
                      return const _InfoCard(
                        message:
                            'Не удалось загрузить список потенциальных хозяев.',
                      );
                    }

                    if (!adopterSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final adopters = adopterSnapshot.data!.items;

                    if (animals.isEmpty) {
                      return const _InfoCard(
                        message:
                            'Сейчас нет доступных питомцев для пристройства.',
                      );
                    }

                    if (adopters.isEmpty) {
                      return const _InfoCard(
                        message: 'Сначала добавьте потенциального хозяина.',
                      );
                    }

                    return _buildForm(animals, adopters);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    List<Animal> animals,
    List<Adopter> adopters,
  ) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Color(0xFFB85C83),
              ),
              const SizedBox(height: 12),
              const Text(
                'Создание заявки',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF30232A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите питомца и потенциального хозяина.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF66555D),
                ),
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<int>(
                initialValue: _selectedAnimalId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Питомец',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                items: animals.map((animal) {
                  return DropdownMenuItem<int>(
                    value: animal.id,
                    child: Text(
                      '${animal.name} — ${animal.species}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAnimalId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите питомца';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _selectedAdopterId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Потенциальный хозяин',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: adopters.map((adopter) {
                  return DropdownMenuItem<int>(
                    value: adopter.id,
                    child: Text(
                      adopter.fullName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAdopterId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите потенциального хозяина';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Дополнительная информация к заявке',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.comment_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _loading ? null : _createRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB85C83),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _loading ? 'Создание заявки...' : 'Создать заявку',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String message;

  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF30232A),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
