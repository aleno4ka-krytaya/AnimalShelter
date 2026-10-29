import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth_session.dart';
import 'core/supabase_config.dart';

import 'repositories/auth_api.dart';
import 'repositories/animal_repository.dart';
import 'repositories/adopter_repository.dart';
import 'repositories/adoption_request_repository.dart';
import 'repositories/medical_card_repository.dart';

import 'repositories/supabase_animal_repository.dart';
import 'repositories/supabase_adopter_repository.dart';
import 'repositories/supabase_adoption_request_repository.dart';
import 'repositories/supabase_medical_card_repository.dart';

import 'state/auth_notifier.dart';
import 'state/animal_notifier.dart';
import 'state/adopter_notifier.dart';
import 'state/adoption_request_notifier.dart';

import 'router.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  final supabase = Supabase.instance.client;
  final prefs = await SharedPreferences.getInstance();

  // AuthApi использует Supabase Auth, а данные приложения
  // загружаются через Supabase-репозитории.
  final authSession = AuthSession();
  final authApi = AuthApi(supabase);

  final auth = AuthNotifier(
    prefs: prefs,
    api: authApi,
    session: authSession,
  );

  authSession.refreshHandler = auth.refreshTokens;
  authSession.expiredHandler = () => auth.logout(notifyServer: false);

  await auth.restore();

  final router = createRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: supabase),
        Provider<AuthApi>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        ProxyProvider<SupabaseClient, AnimalRepository>(
          update: (_, client, __) => SupabaseAnimalRepository(client),
        ),
        ProxyProvider<SupabaseClient, AdopterRepository>(
          update: (_, client, __) => SupabaseAdopterRepository(client),
        ),
        ProxyProvider<SupabaseClient, AdoptionRequestRepository>(
          update: (_, client, __) =>
              SupabaseAdoptionRequestRepository(client),
        ),
        ProxyProvider<SupabaseClient, MedicalCardRepository>(
          update: (_, client, __) =>
              SupabaseMedicalCardRepository(client),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AnimalNotifier(context.read<AnimalRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AdopterNotifier(context.read<AdopterRepository>()),
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
      routerConfig: router,
      builder: (context, child) {
        return Consumer<AuthNotifier>(
          builder: (context, currentAuth, _) {
            return InactivityWatcher(
              enabled: currentAuth.isAuthenticated,
              timeout: const Duration(minutes: 3),
              warningBefore: const Duration(seconds: 30),
              onTimeout: () => currentAuth.logout(),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}