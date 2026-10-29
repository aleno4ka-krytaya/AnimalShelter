import 'package:go_router/go_router.dart';

import 'models/app_user.dart';
import 'screens/admin_users_screen.dart';
import 'screens/adopter_detail_screen.dart';
import 'screens/adopter_list_screen.dart';
import 'screens/adoption_request_form_screen.dart';
import 'screens/animal_detail_screen.dart';
import 'screens/animal_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/medical_card_screen.dart';
import 'screens/register_screen.dart';
import 'state/auth_notifier.dart';

import 'package:flutter/foundation.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final loggedIn = auth.isAuthenticated;
      debugPrint(
        '[ROUTER] path=$path, '
        'loggedIn=$loggedIn, '
        'role=${auth.user?.role.name}, '
        'isAdmin=${auth.has(UserRole.admin)}',
      );
      final isPublic = path == '/login' || path == '/register';

      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && isPublic) {
        final from = state.uri.queryParameters['from'];

        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('//') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register')) {
          return from;
        }

        return '/';
      }

      final requiresStaff = path == '/adopters' ||
          path.startsWith('/adopters/') ||
          path.contains('/medical') ||
          path.startsWith('/adoption-requests');

      if (requiresStaff && !auth.has(UserRole.staff)) {
        return '/forbidden';
      }

      if (path == '/admin/users' && !auth.has(UserRole.admin)) {
        return '/forbidden';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/animals',
        builder: (context, state) => AnimalListScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/animals/:id/medical',
        builder: (context, state) {
          final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              0;

          return MedicalCardScreen(animalId: id);
        },
      ),
      GoRoute(
        path: '/animals/:id',
        builder: (context, state) {
          final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              0;

          return AnimalDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/adopters',
        builder: (context, state) => AdopterListScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/adopters/:id',
        builder: (context, state) {
          final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              0;

          return AdopterDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/adoption-requests/new',
        builder: (context, state) => const AdoptionRequestFormScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
    ],
  );
}
