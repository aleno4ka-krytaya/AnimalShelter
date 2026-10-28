import 'package:go_router/go_router.dart';

import 'models/app_user.dart';
import 'state/auth_notifier.dart';

import 'screens/home_screen.dart';
import 'screens/animal_list_screen.dart';
import 'screens/adopter_list_screen.dart';
import 'screens/animal_detail_screen.dart';
import 'screens/medical_card_screen.dart';
import 'screens/adopter_detail_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/admin_users_screen.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    // При первом открытии переходим на авторизацию.
    initialLocation: '/login',

    // Обновляем маршруты при входе и выходе пользователя.
    refreshListenable: auth,

    redirect: (context, state) {
      final path = state.uri.path;

      final isLogin = path == '/login';
      final isRegister = path == '/register';
      final isPublic = isLogin || isRegister;

      // Без авторизации разрешены только вход и регистрация.
      if (!auth.isAuthenticated && !isPublic) {
        final destination = state.uri.toString();

        return '/login?from=${Uri.encodeComponent(destination)}';
      }

      // После входа не оставляем пользователя на форме входа.
      if (auth.isAuthenticated && isPublic) {
        final from = state.uri.queryParameters['from'];

        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('//')) {
          return from;
        }

        return '/';
      }

      // Разделы сотрудников приюта.
      final staffOnly =
          path == '/adopters' ||
          path.startsWith('/adopters/') ||
          path.contains('/medical') ||
          path.startsWith('/adoption-requests');

      if (staffOnly && !auth.has(UserRole.staff)) {
        return '/forbidden';
      }

      // Управление пользователями — только администратор.
      if (path == '/admin/users' &&
          !auth.has(UserRole.admin)) {
        return '/forbidden';
      }

      return null;
    },

    errorBuilder: (context, state) {
      return NotFoundScreen(
        location: state.uri.toString(),
      );
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return LoginScreen(
            from: state.uri.queryParameters['from'],
            registered:
                state.uri.queryParameters['registered'] == 'true',
          );
        },
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) {
          return const RegisterScreen();
        },
      ),

      GoRoute(
        path: '/forbidden',
        builder: (context, state) {
          return const ForbiddenScreen();
        },
      ),

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      GoRoute(
        path: '/animals',
        builder: (context, state) {
          return AnimalListScreen(uri: state.uri);
        },
      ),

      GoRoute(
        path: '/animals/:id',
        builder: (context, state) {
          return AnimalDetailScreen(
            id: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          );
        },
      ),

      GoRoute(
        path: '/animals/:id/medical',
        builder: (context, state) {
          return MedicalCardScreen(
            animalId: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          );
        },
      ),

      GoRoute(
        path: '/adopters',
        builder: (context, state) {
          return AdopterListScreen(uri: state.uri);
        },
      ),

      GoRoute(
        path: '/adopters/:id',
        builder: (context, state) {
          return AdopterDetailScreen(
            id: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          );
        },
      ),

      GoRoute(
        path: '/admin/users',
        builder: (context, state) {
          return const AdminUsersScreen();
        },
      ),
    ],
  );
}