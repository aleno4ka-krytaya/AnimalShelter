import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_session.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';
  static const _startedAtKey = 'auth_session_started_at';

  static const maxSessionDuration = Duration(hours: 8);

  final SharedPreferences prefs;
  final AuthApi api;
  final AuthSession session;

  AppUser? _user;
  String? _error;
  bool _busy = false;

  Timer? _maximumSessionTimer;

  AuthNotifier({
    required this.prefs,
    required this.api,
    required this.session,
  });

  AppUser? get user => _user;

  String? get error => _error;

  bool get isBusy => _busy;

  String? get accessToken => session.accessToken;

  bool get isAuthenticated =>
      _user != null && session.accessToken != null;

  bool has(UserRole minimumRole) {
    return _user?.role.hasAtLeast(minimumRole) ?? false;
  }

  Future<void> restore() async {
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    final cachedUser = prefs.getString(_userKey);
    final startedAtValue = prefs.getString(_startedAtKey);

    if (access == null || refresh == null) {
      await _clearLocalSession();
      return;
    }

    session.setTokens(
      access: access,
      refresh: refresh,
    );

    DateTime? startedAt;

    if (startedAtValue != null) {
      startedAt = DateTime.tryParse(startedAtValue);

      if (startedAt != null &&
          DateTime.now().difference(startedAt) >=
              maxSessionDuration) {
        await _clearLocalSession();
        return;
      }
    }

    if (cachedUser != null) {
      try {
        _user = AppUser.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(cachedUser) as Map,
          ),
        );
      } catch (_) {
        _user = null;
      }
    }

    if (startedAt != null) {
      _scheduleMaximumSession(startedAt);
    }

    try {
      // Сервер проверяет токен и возвращает актуальную роль.
      _user = await api.me();

      await prefs.setString(
        _userKey,
        jsonEncode(_user!.toJson()),
      );
    } on UnauthorizedException {
      try {
        await refreshTokens();
        _user = await api.me();

        await prefs.setString(
          _userKey,
          jsonEncode(_user!.toJson()),
        );
      } catch (_) {
        await _clearLocalSession();
      }
    } on NetworkException {
      // При сетевой ошибке не стираем токены автоматически.
      // Доступ к защищённым данным всё равно проверяет сервер.
    } catch (error) {
      _error = error.toString();
    }

    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setBusy(true);

    try {
      final result = await api.login(
        username: username,
        password: password,
      );

      await _saveTokens(
        result,
        newSession: true,
      );

      _error = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    _setBusy(true);

    try {
      final result = await api.register(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
      );

      _error = null;
      return result;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> refreshTokens() async {
    final oldRefresh = session.refreshToken;

    if (oldRefresh == null) {
      throw const UnauthorizedException(
        'Токен обновления отсутствует. Войдите снова.',
      );
    }

    final result = await api.refresh(oldRefresh);

    await _saveTokens(
      result,
      newSession: false,
    );

    return result.accessToken;
  }

  Future<void> logout({
    bool notifyServer = true,
  }) async {
    final refresh = session.refreshToken;

    if (notifyServer && refresh != null) {
      try {
        await api.logout(refresh);
      } catch (_) {
        // Даже при сетевом сбое локальный выход выполняется.
      }
    }

    await _clearLocalSession();
    notifyListeners();
  }

  Future<void> _saveTokens(
    AuthTokens result, {
    required bool newSession,
  }) async {
    session.setTokens(
      access: result.accessToken,
      refresh: result.refreshToken,
    );

    _user = result.user;

    await prefs.setString(
      _accessKey,
      result.accessToken,
    );

    await prefs.setString(
      _refreshKey,
      result.refreshToken,
    );

    await prefs.setString(
      _userKey,
      jsonEncode(result.user.toJson()),
    );

    if (newSession) {
      final startedAt = DateTime.now();

      await prefs.setString(
        _startedAtKey,
        startedAt.toIso8601String(),
      );

      _scheduleMaximumSession(startedAt);
    }

    notifyListeners();
  }

  void _scheduleMaximumSession(DateTime startedAt) {
    _maximumSessionTimer?.cancel();

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = maxSessionDuration - elapsed;

    if (remaining <= Duration.zero) {
      _maximumSessionTimer = Timer(
        Duration.zero,
        () => logout(),
      );
      return;
    }

    _maximumSessionTimer = Timer(
      remaining,
      () => logout(),
    );
  }

  Future<void> _clearLocalSession() async {
    _maximumSessionTimer?.cancel();
    _maximumSessionTimer = null;

    _user = null;
    _error = null;

    session.clear();

    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
    await prefs.remove(_startedAtKey);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _maximumSessionTimer?.cancel();
    super.dispose();
  }
}