import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/shelter_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShelterScaffold(
      title: 'Лапки и дом',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF6DCE7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Каждой лапке — свой дом',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF30232A),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Каталог подопечных, поиск новых хозяев '
                    'и забота, которая меняет жизнь.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF30232A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 650;

                final cards = [
                  _HomeCard(
                    title: 'Наши питомцы',
                    text: 'Каталог животных, фильтры '
                        'и карточки подопечных.',
                    onTap: () => context.go('/animals'),
                  ),
                  _HomeCard(
                    title: 'Будущие хозяева',
                    text: 'Контакты людей, которые хотят '
                        'подарить дом.',
                    onTap: () => context.go('/adopters'),
                  ),
                ];

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF30232A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF30232A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}