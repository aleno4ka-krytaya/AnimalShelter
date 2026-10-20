
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../repositories/animal_repository.dart';
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
  final name = TextEditingController();
  final breed = TextEditingController();
  final age = TextEditingController();
  final description = TextEditingController();

  String species = 'Кошка';
  String sex = 'Самка';
  String status = 'Ищет дом';

  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      loaded = true;

      if (widget.id != 0) {
        _load();
      }
    }
  }

  Future<void> _load() async {
    final animal = await context
        .read<AnimalRepository>()
        .findById(widget.id);

    if (animal != null && mounted) {
      name.text = animal.name;
      breed.text = animal.breed;
      age.text = '${animal.age}';
      description.text = animal.description;

      setState(() {
        species = animal.species;
        sex = animal.sex;
        status = animal.status;
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    breed.dispose();
    age.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: widget.id == 0
          ? 'Новый питомец'
          : 'Карточка питомца',
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Заполните информацию о подопечном',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: species,
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
                onChanged: (value) {
                  setState(() {
                    species = value ?? species;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: breed,
                decoration: const InputDecoration(
                  labelText: 'Порода',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: sex,
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
                onChanged: (value) {
                  setState(() {
                    sex = value ?? sex;
                  });
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: status,
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
                onChanged: (value) {
                  setState(() {
                    status = value ?? status;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                ),
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () async {
                  final animal = Animal(
                    id: widget.id,
                    name: name.text.trim().isEmpty
                        ? 'Без имени'
                        : name.text.trim(),
                    species: species,
                    breed: breed.text.trim(),
                    age: int.tryParse(age.text) ?? 0,
                    sex: sex,
                    status: status,
                    description: description.text.trim(),
                  );

                  await context
                      .read<AnimalNotifier>()
                      .save(animal);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
