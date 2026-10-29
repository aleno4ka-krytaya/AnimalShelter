import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://onsdvnfrbfskqgjhplhl.supabase.co';

  static const String publishableKey =
      'sb_publishable_7eSQcSDXBn3_HuqGj5p4SA_Yjn6-uwn';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
