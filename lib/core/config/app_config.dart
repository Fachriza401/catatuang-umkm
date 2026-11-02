abstract final class AppConfig {
  static const appName = 'CatatUang';
  static const appTagline = 'Pembukuan digital untuk UMKM';
  static const appVersion = '1.0.0';
  static const authRedirectUrl = 'catatuang://auth-callback';
  static const splashMinimumDuration = Duration(milliseconds: 1600);
  static const maxContentWidth = 480.0;

  static const _defaultSupabaseUrl = 'https://iyfnarwxhnmbflwrgbhq.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_iHLfWqN6Y64Fj7HKaxpxeQ_F8F2N7h6';

  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultPublishableKey,
  );
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _supabaseUrl.trim();

  static String get supabaseKey {
    final publishableKey = _publishableKey.trim();
    return publishableKey.isNotEmpty ? publishableKey : _anonKey.trim();
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
