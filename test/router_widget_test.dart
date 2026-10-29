import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:animal_shelter/core/auth_session.dart';
import 'package:animal_shelter/main.dart';
import 'package:animal_shelter/repositories/auth_api.dart';
import 'package:animal_shelter/router.dart';
import 'package:animal_shelter/state/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
      ({
        AuthNotifier auth,
        SupabaseClient supabase,
        dynamic router,
      })> setup() async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession();

    // РўРµСЃС‚РѕРІС‹Р№ РєР»РёРµРЅС‚ Supabase Р±РµР· СЃРµС‚РµРІС‹С… Р·Р°РїСЂРѕСЃРѕРІ
    // Рё Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРѕРіРѕ РѕР±РЅРѕРІР»РµРЅРёСЏ С‚РѕРєРµРЅРѕРІ.
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

    return (
      auth: auth,
      supabase: supabase,
      router: router,
    );
  }

  Future<void> disposeSetup(
    ({
      AuthNotifier auth,
      SupabaseClient supabase,
      dynamic router,
    }) setup,
  ) async {
    setup.router.dispose();
    setup.auth.dispose();
  }

  testWidgets(
    'Р РµРіРёСЃС‚СЂР°С†РёСЏ РґРѕСЃС‚СѓРїРЅР° Р±РµР· Р°РІС‚РѕСЂРёР·Р°С†РёРё',
    (tester) async {
      final s = await setup();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: s.auth,
          child: ShelterApp(
            router: s.router,
            auth: s.auth,
          ),
        ),
      );

      s.router.go('/register');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        s.router.routeInformationProvider.value.uri.path,
        '/register',
      );

      await disposeSetup(s);
    },
  );

  testWidgets(
    'РќРµР°РІС‚РѕСЂРёР·РѕРІР°РЅРЅС‹Р№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РїРµСЂРµРЅР°РїСЂР°РІР»СЏРµС‚СЃСЏ РЅР° РІС…РѕРґ',
    (tester) async {
      final s = await setup();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: s.auth,
          child: ShelterApp(
            router: s.router,
            auth: s.auth,
          ),
        ),
      );

      s.router.go('/adopters');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        s.router.routeInformationProvider.value.uri.path,
        '/login',
      );

      await disposeSetup(s);
    },
  );

  testWidgets(
    'РЎС‚СЂР°РЅРёС†Р° РІС…РѕРґР° РґРѕСЃС‚СѓРїРЅР° Р±РµР· Р°РІС‚РѕСЂРёР·Р°С†РёРё',
    (tester) async {
      final s = await setup();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: s.auth,
          child: ShelterApp(
            router: s.router,
            auth: s.auth,
          ),
        ),
      );

      s.router.go('/login');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        s.router.routeInformationProvider.value.uri.path,
        '/login',
      );

      await disposeSetup(s);
    },
  );

  testWidgets(
    'РђРґРјРёРЅРёСЃС‚СЂР°С‚РёРІРЅР°СЏ СЃС‚СЂР°РЅРёС†Р° РЅРµРґРѕСЃС‚СѓРїРЅР° Р±РµР· РІС…РѕРґР°',
    (tester) async {
      final s = await setup();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthNotifier>.value(
          value: s.auth,
          child: ShelterApp(
            router: s.router,
            auth: s.auth,
          ),
        ),
      );

      s.router.go('/admin/users');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        s.router.routeInformationProvider.value.uri.path,
        '/login',
      );

      await disposeSetup(s);
    },
  );
}
