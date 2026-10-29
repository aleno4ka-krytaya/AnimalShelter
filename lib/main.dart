import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';

import 'repositories/auth_api.dart';
import 'repositories/animal_repository.dart';
import 'repositories/adopter_repository.dart';
import 'repositories/adoption_request_repository.dart';
import 'repositories/medical_card_repository.dart';

import 'repositories/api_animal_repository.dart';
import 'repositories/api_adopter_repository.dart';
import 'repositories/api_adoption_request_repository.dart';
import 'repositories/api_medical_card_repository.dart';

import 'state/auth_notifier.dart';
import 'state/animal_notifier.dart';
import 'state/adopter_notifier.dart';
import 'state/adoption_request_notifier.dart';

import 'router.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Общая сессия пользователя.
  final session = AuthSession();

  // Один Dio для авторизации и запросов к API.
  final dio = buildDio(
    authSession: session,
  );

  final authApi = AuthApi(dio);

  final auth = AuthNotifier(
    prefs: prefs,
    api: authApi,
    session: session,
  );

  // Автоматическое обновление токена.
  session.refreshHandler = auth.refreshTokens;

  // Если обновить токен не удалось — завершаем сессию.
  session.expiredHandler = () {
    return auth.logout(notifyServer: false);
  };

  // Восстанавливаем сессию до построения интерфейса.
  await auth.restore();

  // Создаём маршрутизатор с авторизацией.
  final router = createRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(
          value: dio,
        ),

        Provider<AuthApi>.value(
          value: authApi,
        ),

        ChangeNotifierProvider<AuthNotifier>.value(
          value: auth,
        ),

        // Репозитории работают через REST API.
        ProxyProvider<Dio, AnimalRepository>(
          update: (_, dio, __) {
            return ApiAnimalRepository(dio);
          },
        ),

        ProxyProvider<Dio, AdopterRepository>(
          update: (_, dio, __) {
            return ApiAdopterRepository(dio);
          },
        ),

        ProxyProvider<Dio, AdoptionRequestRepository>(
          update: (_, dio, __) {
            return ApiAdoptionRequestRepository(dio);
          },
        ),

        ProxyProvider<Dio, MedicalCardRepository>(
          update: (_, dio, __) {
            return ApiMedicalCardRepository(dio);
          },
        ),

        // Состояния приложения.
        ChangeNotifierProvider(
          create: (context) => AnimalNotifier(
            context.read<AnimalRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => AdopterNotifier(
            context.read<AdopterRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => AdoptionRequestNotifier(
            context.read<AdoptionRequestRepository>(),
            context.read<AnimalRepository>(),
          ),
        ),
      ],
      child: ShelterApp(
        router: router,
        auth: auth,
      ),
    ),
  );
}

class ShelterApp extends StatelessWidget {
  final RouterConfig<Object> router;
  final AuthNotifier auth;

  const ShelterApp({
    super.key,
    required this.router,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFF6DCE7);
    const deepPink = Color(0xFFB85C83);
    const darkText = Color(0xFF30232A);

    return MaterialApp.router(
      title: 'Лапки и дом',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepPink,
          surface: const Color(0xFFFFFAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: pink,
          foregroundColor: darkText,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFEBC5D5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFEBC5D5),
            ),
          ),
        ),
      ),

      // Именно этот маршрутизатор проверяет авторизацию.
      routerConfig: router,

      // Сессия ограничена по времени и бездействию.
      builder: (context, child) {
        return Consumer<AuthNotifier>(
          builder: (context, currentAuth, _) {
            return InactivityWatcher(
              enabled: currentAuth.isAuthenticated,
              timeout: const Duration(minutes: 3),
              warningBefore: const Duration(seconds: 30),
              onTimeout: () {
                return currentAuth.logout();
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
