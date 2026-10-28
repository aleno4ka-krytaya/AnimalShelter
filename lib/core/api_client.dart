import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl.endsWith('/')
          ? apiBaseUrl
          : '$apiBaseUrl/',

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),

      headers: const {
        'Content-Type': 'application/json',
      },

      validateStatus: (status) =>
          status != null && status < 500,
    ),
  );

  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Параметры для демонстрации ПР4:
        // ?__delay=1500 и ?__fail=500
        final browserFlags = Uri.base.queryParameters;

        for (final key in const [
          '__delay',
          '__fail',
        ]) {
          if (browserFlags.containsKey(key)) {
            options.queryParameters.putIfAbsent(
              key,
              () => browserFlags[key],
            );
          }
        }

        final token = tokenProvider?.call();

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
        final status = response.statusCode ?? 0;

        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} -> $status',
          );
        }

        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
          return;
        }

        handler.next(response);
      },

      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ${error.requestOptions.method} '
            '${error.requestOptions.uri} -> '
            '${error.response?.statusCode ?? error.type}',
          );
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}

ApiException mapHttpError(
  int status,
  dynamic data,
) {
  final payload = data is Map
      ? data
      : const <dynamic, dynamic>{};

  final message =
      (payload['message'] ?? 'Ошибка HTTP $status').toString();

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