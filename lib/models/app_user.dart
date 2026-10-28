enum UserRole {
  visitor,
  staff,
  admin;

  static UserRole fromValue(Object? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value?.toString(),
      orElse: () => UserRole.visitor,
    );
  }

  int get level {
    switch (this) {
      case UserRole.visitor:
        return 0;
      case UserRole.staff:
        return 1;
      case UserRole.admin:
        return 2;
    }
  }

  String get title {
    switch (this) {
      case UserRole.visitor:
        return 'Посетитель';
      case UserRole.staff:
        return 'Сотрудник приюта';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  bool hasAtLeast(UserRole minimum) {
    return level >= minimum.level;
  }
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromValue(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role.name,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
    );
  }
}