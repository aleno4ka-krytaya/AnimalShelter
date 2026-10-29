import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../models/medical_card.dart';
import '../repositories/animal_repository.dart';
import '../repositories/medical_card_repository.dart';
import '../widgets/shelter_scaffold.dart';

class MedicalCardScreen extends StatefulWidget {
  final int animalId;

  const MedicalCardScreen({
    super.key,
    required this.animalId,
  });

  @override
  State<MedicalCardScreen> createState() => _MedicalCardScreenState();
}

class _MedicalCardScreenState extends State<MedicalCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passport = TextEditingController();
  final _microchip = TextEditingController();
  final _vaccinations = TextEditingController();
  final _allergies = TextEditingController();

  Animal? _animal;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final animalRepository = context.read<AnimalRepository>();
    final medicalCardRepository = context.read<MedicalCardRepository>();

    try {
      final animal = await animalRepository.findById(widget.animalId);

      if (!mounted) return;

      if (animal == null) {
        setState(() {
          _animal = null;
          _error = 'Питомец не найден.';
          _loading = false;
        });
        return;
      }

      final card = await medicalCardRepository.findByAnimalId(widget.animalId);

      if (!mounted) return;

      _animal = animal;
      _passport.text = card.passportNumber;
      _microchip.text = card.microchipNumber;
      _vaccinations.text = card.vaccinationNotes;
      _allergies.text = card.allergies;

      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Не удалось загрузить веткарточку: $error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _passport.dispose();
    _microchip.dispose();
    _vaccinations.dispose();
    _allergies.dispose();
    super.dispose();
  }

  String _shown(String value) {
    return value.trim().isEmpty ? 'Не заполнено' : value.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving || _animal == null) {
      return;
    }

    setState(() => _saving = true);

    try {
      final repository = context.read<MedicalCardRepository>();

      await repository.save(
        MedicalCard(
          animalId: widget.animalId,
          passportNumber: _passport.text.trim(),
          microchipNumber: _microchip.text.trim(),
          vaccinationNotes: _vaccinations.text.trim(),
          allergies: _allergies.text.trim(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ветеринарная карточка сохранена'),
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить карточку: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: 'Ветеринарная карточка',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _animal == null
                  ? const Center(
                      child: Text('Питомец не найден.'),
                    )
                  : SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Color(0xFFF6DCE7),
                                            child: Icon(
                                              Icons.medical_services_outlined,
                                              color: Color(0xFFB85C83),
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _animal!.name,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_animal!.species} • '
                                                  '${_animal!.breed} • '
                                                  '${_animal!.age} лет',
                                                ),
                                                Text(
                                                  'Статус: ${_animal!.status}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 28),
                                      const Text(
                                        'Данные ветеринарной карточки',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _InfoRow(
                                        label: 'Номер ветпаспорта',
                                        value: _shown(_passport.text),
                                      ),
                                      _InfoRow(
                                        label: 'Номер микрочипа',
                                        value: _shown(_microchip.text),
                                      ),
                                      _InfoRow(
                                        label: 'Прививки и процедуры',
                                        value: _shown(_vaccinations.text),
                                      ),
                                      _InfoRow(
                                        label: 'Аллергии и примечания',
                                        value: _shown(_allergies.text),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Редактирование карточки',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _passport,
                                      decoration: const InputDecoration(
                                        labelText: 'Номер ветпаспорта',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _microchip,
                                      decoration: const InputDecoration(
                                        labelText: 'Номер микрочипа',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _vaccinations,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Прививки и процедуры',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _allergies,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Аллергии / примечания',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: _saving ? null : _save,
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.save_outlined,
                                            ),
                                      label: Text(
                                        _saving
                                            ? 'Сохранение...'
                                            : 'Сохранить ветеринарную карточку',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => context.go(
                                        '/animals/${widget.animalId}',
                                      ),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text(
                                        'Вернуться к карточке питомца',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Примечание: в текущей версии данные '
                                      'хранятся в памяти приложения и '
                                      'сбрасываются после перезапуска.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      );
}
