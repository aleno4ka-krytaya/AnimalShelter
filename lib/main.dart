
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/animal_repository.dart';
import 'repositories/adopter_repository.dart';
import 'state/animal_notifier.dart';
import 'state/adopter_notifier.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<AnimalRepository>(
          create: (_) => InMemoryAnimalRepository(),
        ),
        Provider<AdopterRepository>(
          create: (_) => InMemoryAdopterRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AnimalNotifier(context.read<AnimalRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AdopterNotifier(context.read<AdopterRepository>())..load(),
        ),
      ],
      child: const ShelterApp(),
    ),
  );
}

class ShelterApp extends StatelessWidget {
  const ShelterApp({super.key});

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFF6DCE7);
    const deepPink = Color(0xFFB85C83);

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
          foregroundColor: Color(0xFF30232A),
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
      routerConfig: createRouter(),
    );
  }
}
