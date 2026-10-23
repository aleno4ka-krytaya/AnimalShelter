import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/animal_list_screen.dart';
import 'screens/adopter_list_screen.dart';
import 'screens/animal_detail_screen.dart';
import 'screens/medical_card_screen.dart';
import 'screens/adopter_detail_screen.dart';
import 'screens/not_found_screen.dart';

GoRouter createRouter() => GoRouter(
      initialLocation: '/',
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/animals',
          builder: (context, state) =>
              AnimalListScreen(uri: state.uri),
        ),
        GoRoute(
          path: '/animals/:id',
          builder: (context, state) => AnimalDetailScreen(
            id: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          ),
        ),
        GoRoute(
          path: '/animals/:id/medical',
          builder: (context, state) => MedicalCardScreen(
            animalId: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          ),
        ),
        GoRoute(
          path: '/adopters',
          builder: (context, state) =>
              AdopterListScreen(uri: state.uri),
        ),
        GoRoute(
          path: '/adopters/:id',
          builder: (context, state) => AdopterDetailScreen(
            id: int.tryParse(
                  state.pathParameters['id'] ?? '',
                ) ??
                0,
          ),
        ),
      ],
    );