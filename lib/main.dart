import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';

import 'repositories/adopter_repository.dart';
import 'repositories/adoption_request_repository.dart';
import 'repositories/animal_repository.dart';
import 'repositories/medical_card_repository.dart';

import 'repositories/api_adopter_repository.dart';
import 'repositories/api_adoption_request_repository.dart';
import 'repositories/api_animal_repository.dart';
import 'repositories/api_medical_card_repository.dart';

import 'state/adopter_notifier.dart';
import 'state/adoption_request_notifier.dart';
import 'state/animal_notifier.dart';

import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>(
          create: (_) => buildDio(),
          dispose: (_, dio) => dio.close(force: true),
        ),

        ProxyProvider<Dio, AnimalRepository>(
          update: (_, dio, __) => ApiAnimalRepository(dio),
        ),

        ProxyProvider<Dio, AdopterRepository>(
          update: (_, dio, __) => ApiAdopterRepository(dio),
        ),

        ProxyProvider<Dio, AdoptionRequestRepository>(
          update: (_, dio, __) =>
              ApiAdoptionRequestRepository(dio),
        ),

        ProxyProvider<Dio, MedicalCardRepository>(
          update: (_, dio, __) =>
              ApiMedicalCardRepository(dio),
        ),

        ChangeNotifierProvider(
          create: (context) => AnimalNotifier(
            context.read<AnimalRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider(
          create: (context) => AdopterNotifier(
            context.read<AdopterRepository>(),
          )..load(),
        ),

        ChangeNotifierProvider(
          create: (context) => AdoptionRequestNotifier(
            context.read<AdoptionRequestRepository>(),
            context.read<AnimalRepository>(),
          )..load(),
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

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      routerConfig: createRouter(),
    );
  }
}