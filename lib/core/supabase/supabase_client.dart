import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client singleton for StudySync Syria.
///
/// Reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the bundled `.env`
/// file (loaded via `flutter_dotenv`) and exposes the initialized
/// [SupabaseClient] used everywhere in the app.
///
/// IMPORTANT:
/// - Only the Supabase **anon** key is used in the app. Never embed the
///   service role key in client code.
/// - Call [SupabaseService.init] once, before `runApp`, in `main.dart`.
class SupabaseService {
  SupabaseService._();

  static const String _envUrlKey = 'SUPABASE_URL';
  static const String _envAnonKeyKey = 'SUPABASE_ANON_KEY';

  /// Initializes Supabase. Must be awaited before `runApp`.
  ///
  /// Throws [StateError] if the required env vars are missing so the
  /// problem surfaces immediately during development instead of failing
  /// silently at the first network call.
  static Future<void> init() async {
    final String url = dotenv.maybeGet(_envUrlKey)?.trim() ?? '';
    final String anonKey = dotenv.maybeGet(_envAnonKeyKey)?.trim() ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Make sure .env contains '
        '$_envUrlKey and $_envAnonKeyKey, and that .env is listed under '
        'flutter > assets in pubspec.yaml.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// The shared [SupabaseClient]. Safe to use after [init] has resolved.
  static SupabaseClient get client => Supabase.instance.client;

  /// Convenience accessor for [GoTrueClient].
  static GoTrueClient get auth => client.auth;
}
