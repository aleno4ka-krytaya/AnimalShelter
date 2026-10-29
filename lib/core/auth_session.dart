class AuthSession {
  String? accessToken;
  String? refreshToken;

  Future<String?> Function()? refreshHandler;
  Future<void> Function()? expiredHandler;

  Future<String?>? _refreshFuture;

  void setTokens({
    required String access,
    required String refresh,
  }) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }

  Future<String?> refreshAccessToken() {
    final existing = _refreshFuture;

    if (existing != null) {
      return existing;
    }

    final handler = refreshHandler;

    if (handler == null) {
      return Future<String?>.value(null);
    }

    final future = handler();
    _refreshFuture = future;

    return future.whenComplete(() {
      _refreshFuture = null;
    });
  }
}
