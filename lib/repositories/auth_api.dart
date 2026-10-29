import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/app_user.dart';

class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'auth/login',
        data: {
          'username': username,
          'password': password,
        },
      ),
    );

    return AuthTokens.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'auth/register',
        data: {
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
        },
      ),
    );

    return AppUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AppUser> me() async {
    final response = await apiRequest(
      () => dio.get<dynamic>('auth/me'),
    );

    return AppUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await apiRequest(
      () => dio.post<dynamic>(
        'auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      ),
    );

    return AuthTokens.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> logout(String refreshToken) async {
    await apiRequest(
      () => dio.post<dynamic>(
        'auth/logout',
        data: {
          'refreshToken': refreshToken,
        },
      ),
    );
  }

  Future<List<AppUser>> users() async {
    final response = await apiRequest(
      () => dio.get<dynamic>('auth/users'),
    );

    if (response.data is! List) {
      throw const FormatException(
        'Сервер вернул неверный список пользователей.',
      );
    }

    return (response.data as List)
        .whereType<Map>()
        .map(
          (item) => AppUser.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<AppUser> setRole(
    int userId,
    UserRole role,
  ) async {
    final response = await apiRequest(
      () => dio.put<dynamic>(
        'auth/users/$userId/role',
        data: {
          'role': role.name,
        },
      ),
    );

    return AppUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
