import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';

class AuthApi {
  final SupabaseClient client;

  AuthApi(this.client);

  Future<AppUser> _loadProfile(String userId) async {
    final row =
        await client.from('profiles').select().eq('id', userId).single();

    final user = client.auth.currentUser;

    return AppUser.fromJson({
      ...Map<String, dynamic>.from(row),
      'id': userId,
      'email': row['email'] ?? user?.email ?? '',
    });
  }

  AuthTokens _tokensFromSession(
    Session session,
    AppUser user,
  ) {
    return AuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      expiresIn: 3600,
      user: user,
    );
  }

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    // Поле username в старом интерфейсе теперь принимает email.
    final response = await client.auth.signInWithPassword(
      email: username.trim(),
      password: password,
    );

    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      throw const AuthException(
        'Не удалось войти. Проверьте email и пароль.',
      );
    }

    final profile = await _loadProfile(user.id);

    return _tokensFromSession(session, profile);
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim(),
        'fullName': fullName.trim(),
      },
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Не удалось создать пользователя.',
      );
    }

    // При включённом подтверждении email сессия появится
    // только после подтверждения адреса.
    if (response.session != null) {
      return _loadProfile(user.id);
    }

    return AppUser(
      id: user.id,
      username: username.trim(),
      fullName: fullName.trim(),
      email: email.trim(),
      role: UserRole.visitor,
    );
  }

  Future<AppUser> me() async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw const UnauthorizedException(
        'Сессия завершена. Войдите снова.',
      );
    }

    return _loadProfile(user.id);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await client.auth.refreshSession(refreshToken);
    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      throw const UnauthorizedException(
        'Не удалось обновить сессию. Войдите снова.',
      );
    }

    final profile = await _loadProfile(user.id);

    return _tokensFromSession(session, profile);
  }

  Future<void> logout(String refreshToken) async {
    await client.auth.signOut();
  }

  Future<List<AppUser>> users() async {
    final rows = await client.from('profiles').select().order('full_name');

    return rows
        .map(
          (row) => AppUser.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<AppUser> setRole(String userId, UserRole role) async {
    final row = await client
        .from('profiles')
        .update({'role': role.name})
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(Map<String, dynamic>.from(row));
  }
}
