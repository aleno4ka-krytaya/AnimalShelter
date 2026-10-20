import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShelterScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const ShelterScaffold({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        TextButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home_outlined), label: const Text('Главная')),
        const SizedBox(width: 12),
      ],
    ),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Padding(padding: const EdgeInsets.all(20), child: child))),
  );
}
