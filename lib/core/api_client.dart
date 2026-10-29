import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'auth_session.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  HttpClientAdapter? adapter,
  AuthSession? authSession,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
      },

      // Ответы 4xx и 5xx должны обрабатываться через onError.
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authSession?.accessToken ?? tokenProvider?.call();

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint(
            '[API] ${options.method} ${options.uri}',
          );
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            '-> ${response.statusCode}',
          );
        }

        handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path.toLowerCase();

        final isAuthEndpoint =
            path.contains('/auth/') || path.startsWith('auth/');

        final alreadyRetried =
            error.requestOptions.extra['authRetried'] == true;

        if (kDebugMode) {
          debugPrint(
            '[API] ${error.requestOptions.method} '
            '${error.requestOptions.uri} '
            '-> ${status ?? error.type}',
          );
        }

        // Обновляем токен при 401, но не запускаем повторное
        // обновление для login, register и refresh.
        if (status == 401 &&
            !isAuthEndpoint &&
            !alreadyRetried &&
            authSession != null) {
          try {
            final newToken = await authSession.refreshAccessToken();

            if (newToken == null || newToken.isEmpty) {
              throw const UnauthorizedException(
                'Не удалось обновить токен.',
              );
            }

            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            options.extra['authRetried'] = true;

            final response = await dio.fetch<dynamic>(options);

            handler.resolve(response);
            return;
          } catch (_) {
            await authSession.expiredHandler?.call();
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}

ApiException mapHttpError(int status, dynamic data) {
  final payload = data is Map ? data : const <dynamic, dynamic>{};

  final message = (payload['message'] ?? 'Ошибка HTTP $status').toString();

  switch (status) {
    case 400:
      return UnexpectedApiException(message);
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 409:
      return ConflictException(message);
    case 422:
      final rawErrors = payload['errors'];
      final errors = <String, String>{};

      if (rawErrors is Map) {
        for (final entry in rawErrors.entries) {
          errors[entry.key.toString()] = entry.value.toString();
        }
      }

      return ValidationException(
        message,
        errors: errors,
      );
    default:
      if (status >= 500) {
        return ServerException(message);
      }

      return UnexpectedApiException(message);
  }
}

ApiException mapDioException(DioException error) {
  final nestedError = error.error;

  if (nestedError is ApiException) {
    return nestedError;
  }

  if (error.type == DioExceptionType.cancel) {
    return const RequestCancelledException();
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const RequestTimeoutException();
  }

  if (error.response?.statusCode != null) {
    return mapHttpError(
      error.response!.statusCode!,
      error.response!.data,
    );
  }

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown) {
    return const NetworkException();
  }

  return UnexpectedApiException(
    error.message ?? 'Неизвестная ошибка сети.',
  );
}

Future<T> apiRequest<T>(
  Future<T> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw mapDioException(error);
  }
}

Future<T> apiRead<T>(
  Future<T> Function() request, {
  int attempts = 3,
}) async {
  var attempt = 0;

  while (true) {
    attempt++;

    try {
      return await apiRequest(request);
    } on NetworkException {
      if (attempt >= attempts) rethrow;
    } on RequestTimeoutException {
      if (attempt >= attempts) rethrow;
    } on ServerException {
      if (attempt >= attempts) rethrow;
    }

    await Future<void>.delayed(
      Duration(milliseconds: 250 * attempt),
    );
  }
}
