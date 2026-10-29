import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class ShelterScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const ShelterScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthNotifier>();

    await auth.logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 500;
    final isTablet = width < 800;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isMobile ? 12 : 20,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 17 : 22,
          ),
        ),
        actions: [
          if (user != null && !isMobile)
            Flexible(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${user.fullName} · ${user.role.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Главная',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Выйти',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
            )
          else
            Padding(
              padding: EdgeInsets.only(
                right: isTablet ? 8 : 16,
                left: 4,
              ),
              child: FilledButton.tonalIcon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: child,
          ),
        ),
      ),
    );
  }
}
