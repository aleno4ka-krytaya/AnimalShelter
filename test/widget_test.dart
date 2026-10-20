import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:animal_shelter/main.dart';
import 'package:animal_shelter/repositories/animal_repository.dart';
import 'package:animal_shelter/repositories/adopter_repository.dart';
import 'package:animal_shelter/state/animal_notifier.dart';
import 'package:animal_shelter/state/adopter_notifier.dart';

void main() {
  testWidgets('shows shelter home screen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AnimalRepository>(
            create: (_) => InMemoryAnimalRepository(),
          ),
          Provider<AdopterRepository>(
            create: (_) => InMemoryAdopterRepository(),
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
        ],
        child: const ShelterApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Лапки и дом'), findsOneWidget);
    expect(find.text('Наши питомцы'), findsOneWidget);
    expect(find.text('Будущие хозяева'), findsOneWidget);
  });
}
