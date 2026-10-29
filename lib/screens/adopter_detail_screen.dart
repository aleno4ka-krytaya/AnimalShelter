import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adopter.dart';
import '../repositories/adopter_repository.dart';
import '../state/adopter_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AdopterDetailScreen extends StatefulWidget {
  final int id;

  const AdopterDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<AdopterDetailScreen> createState() => _AdopterDetailScreenState();
}

class _AdopterDetailScreenState extends State<AdopterDetailScreen> {
  final fullName = TextEditingController();
  final city = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  String species = 'Кошка';
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
    final adopter = await context.read<AdopterRepository>().findById(widget.id);

    if (adopter != null && mounted) {
      fullName.text = adopter.fullName;
      city.text = adopter.city;
      phone.text = adopter.phone;
      email.text = adopter.email;

      setState(() {
        species = adopter.preferredSpecies;
      });
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    city.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: widget.id == 0 ? 'Новый хозяин' : 'Карточка будущего хозяина',
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: fullName,
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: const InputDecoration(
                  labelText: 'Город',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: species,
                decoration: const InputDecoration(
                  labelText: 'Предпочитаемый питомец',
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
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final adopter = Adopter(
                    id: widget.id,
                    fullName: fullName.text.trim().isEmpty
                        ? 'Без имени'
                        : fullName.text.trim(),
                    city: city.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    preferredSpecies: species,
                  );

                  await context.read<AdopterNotifier>().save(adopter);

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
