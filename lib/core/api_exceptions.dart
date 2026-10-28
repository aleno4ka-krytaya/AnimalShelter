sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Сервер недоступен. Проверьте соединение и настройки CORS.',
  ]);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([
    super.message =
        'Сервер слишком долго отвечает. Повторите попытку.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = 'Запись не найдена.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Требуется авторизация.',
  ]);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message =
        'Недостаточно прав для выполнения операции.',
  ]);
}

class ConflictException extends ApiException {
  const ConflictException([
    super.message =
        'Операция конфликтует с существующими данными.',
  ]);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;

  const ValidationException(
    super.message, {
    this.errors = const {},
  });
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'На сервере произошла ошибка.',
  ]);
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException()
      : super('Запрос отменён.');
}

class UnexpectedApiException extends ApiException {
  const UnexpectedApiException([
    super.message = 'Не удалось выполнить запрос.',
  ]);
}