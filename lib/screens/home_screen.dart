import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final bool canManageRequests = auth.has(UserRole.staff);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 500;

    return ShelterScaffold(
      title: 'Лапки и дом',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF6DCE7),
                borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Каждому питомцу — заботливый дом',
                    style: TextStyle(
                      fontSize: isMobile ? 27 : 30,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: const Color(0xFF30232A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Помогаем животным найти любящих хозяев. '
                    'Просматривайте питомцев и управляйте '
                    'заявками на пристройство.',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      height: 1.5,
                      color: const Color(0xFF30232A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = <_HomeCard>[
                  _HomeCard(
                    title: 'Наши питомцы',
                    description:
                        'Каталог животных, поиск и ветеринарные карточки.',
                    icon: Icons.pets,
                    onTap: () => context.go('/animals'),
                  ),
                  if (canManageRequests)
                    _HomeCard(
                      title: 'Будущие хозяева',
                      description: 'Список потенциальных хозяев и их контакты.',
                      icon: Icons.people_outline,
                      onTap: () => context.go('/adopters'),
                    ),
                  if (canManageRequests)
                    _HomeCard(
                      title: 'Заявки на пристройство',
                      description:
                          'Создание заявки и выбор потенциального хозяина.',
                      icon: Icons.assignment_outlined,
                      onTap: () => context.go('/adoption-requests/new'),
                    ),
                ];

                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                        ? 2
                        : 1;

                if (columns == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: cards.map((card) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: card,
                      );
                    }).toList(),
                  );
                }

                final spacing = 16.0;
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards.map((card) {
                    return SizedBox(
                      width: cardWidth,
                      child: card,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 500;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: isMobile ? 30 : 36,
                color: const Color(0xFFB85C83),
              ),
              SizedBox(width: isMobile ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF30232A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        height: 1.4,
                        color: const Color(0xFF30232A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFB85C83),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
