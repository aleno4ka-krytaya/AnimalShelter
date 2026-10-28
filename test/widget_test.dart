import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animal_shelter/core/auth_session.dart';
import 'package:animal_shelter/repositories/auth_api.dart';
import 'package:animal_shelter/router.dart';
import 'package:animal_shelter/main.dart';
import 'package:animal_shelter/state/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Неавторизованный пользователь видит страницу входа',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();

      final session = AuthSession();

      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080/api/',
        ),
      );

      final api = AuthApi(dio);

      final auth = AuthNotifier(
        prefs: prefs,
        api: api,
        session: session,
      );

      session.refreshHandler = auth.refreshTokens;

      session.expiredHandler = () {
        return auth.logout(notifyServer: false);
      };

      final router = createRouter(auth);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: auth,
          child: ShelterApp(
            router: router,
            auth: auth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Вход в систему'),
        findsOneWidget,
      );

      dio.close(force: true);
      router.dispose();
    },
  );
}