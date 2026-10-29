import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:animal_shelter/core/auth_session.dart';
import 'package:animal_shelter/main.dart';
import 'package:animal_shelter/repositories/auth_api.dart';
import 'package:animal_shelter/router.dart';
import 'package:animal_shelter/state/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Неавторизованный пользователь видит страницу входа',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final session = AuthSession();

      final supabase = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
        ),
      );

      final authApi = AuthApi(supabase);

      final auth = AuthNotifier(
        prefs: prefs,
        api: authApi,
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
        router.routeInformationProvider.value.uri.path,
        '/login',
      );

      router.dispose();
      auth.dispose();
    },
  );
}
