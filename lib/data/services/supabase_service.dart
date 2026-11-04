import 'package:supabase_flutter/supabase_flutter.dart';

/// Koneksi backend LUMAIR (Supabase).
///
/// Kredensial disuntik lewat --dart-define saat build/run — TIDAK
/// ditulis di dalam kode supaya tidak bocor ke repo:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
///
/// Kalau salah satu kosong → app tetap jalan normal, hanya fitur
/// auth & laporan menampilkan kartu "belum terhubung".
class SupabaseService {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
