import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:animal_shelter/core/auth_session.dart';
import 'package:animal_shelter/main.dart';
import 'package:animal_shelter/repositories/auth_api.dart';
import 'package:animal_shelter/router.dart';
import 'package:animal_shelter/state/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({AuthNotifier auth, Dio dio, dynamic router})> setup() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/'));
    final auth = AuthNotifier(
      prefs: prefs,
      api: AuthApi(dio),
      session: session,
    );
    session.refreshHandler = auth.refreshTokens;
    session.expiredHandler = () => auth.logout(notifyServer: false);
    final router = createRouter(auth);
    return (auth: auth, dio: dio, router: router);
  }

  testWidgets('Регистрация доступна без авторизации', (tester) async {
    final s = await setup();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: s.auth,
        child: ShelterApp(router: s.router, auth: s.auth),
      ),
    );
    s.router.go('/register');
    await tester.pumpAndSettle();

    expect(find.text('Регистрация'), findsOneWidget);

    s.dio.close(force: true);
    s.router.dispose();
    s.auth.dispose();
  });

  testWidgets('Неавторизованный пользователь перенаправляется на вход',
      (tester) async {
    final s = await setup();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: s.auth,
        child: ShelterApp(router: s.router, auth: s.auth),
      ),
    );
    s.router.go('/adopters');
    await tester.pumpAndSettle();

    expect(s.router.routeInformationProvider.value.uri.path, '/login');

    s.dio.close(force: true);
    s.router.dispose();
    s.auth.dispose();
  });

  testWidgets('Неавторизованный пользователь не открывает список животных',
      (tester) async {
    final s = await setup();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: s.auth,
        child: ShelterApp(router: s.router, auth: s.auth),
      ),
    );
    s.router.go('/animals');
    await tester.pumpAndSettle();

    expect(s.router.routeInformationProvider.value.uri.path, '/login');

    s.dio.close(force: true);
    s.router.dispose();
    s.auth.dispose();
  });

  testWidgets('Неавторизованный пользователь не открывает медкарту',
      (tester) async {
    final s = await setup();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: s.auth,
        child: ShelterApp(router: s.router, auth: s.auth),
      ),
    );
    s.router.go('/animals/1/medical');
    await tester.pumpAndSettle();

    expect(s.router.routeInformationProvider.value.uri.path, '/login');

    s.dio.close(force: true);
    s.router.dispose();
    s.auth.dispose();
  });
}
