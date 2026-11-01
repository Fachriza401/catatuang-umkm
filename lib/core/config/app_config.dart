abstract final class AppConfig {
  static const appName = 'CatatUang';
  static const appTagline = 'Pembukuan digital untuk UMKM';
  static const appVersion = '1.0.0';
  static const authRedirectUrl = 'catatuang://auth-callback';
  static const splashMinimumDuration = Duration(milliseconds: 1600);
  static const maxContentWidth = 480.0;

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
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
