import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';
import '../state/auth_notifier.dart';
import '../widgets/shelter_scaffold.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await context.read<AuthApi>().users();

      if (!mounted) return;

      setState(() => _users = users);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;

      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeRole(
    AppUser user,
    UserRole role,
  ) async {
    try {
      await context.read<AuthApi>().setRole(user.id, role);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Роль пользователя ${user.username} изменена.'),
        ),
      );

      await _reload();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthNotifier>().user;

    return ShelterScaffold(
      title: 'Пользователи',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Управление пользователями',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF30232A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Роли: посетитель, сотрудник приюта и администратор.',
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isSelf = user.id == currentUser?.id;

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF6DCE7),
                      child: Icon(
                        Icons.person_outline,
                        color: Color(0xFF30232A),
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text(
                      '${user.username} • ${user.email}',
                    ),
                    trailing: DropdownButton<UserRole>(
                      value: user.role,
                      onChanged: isSelf
                          ? null
                          : (role) {
                              if (role != null) {
                                _changeRole(user, role);
                              }
                            },
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.title),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
