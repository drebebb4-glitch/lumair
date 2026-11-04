import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, Session, SupabaseClient;

import '../data/services/supabase_service.dart';

/// Info akun yang tampil di UI — dibungkus supaya UI tidak
/// tergantung langsung ke tipe Supabase.
class AuthUser {
  final String id;
  final String email;
  final String displayName;
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  static AuthUser? fromSession(Session? s) {
    final email = s?.user.email ?? '';
    if (s == null || email.isEmpty) return null;
    // Nama tampilan: bagian depan email dipercantik ("budi@mail.com" → Budi).
    final base = email.split('@').first;
    final name = base.length <= 1
        ? base.toUpperCase()
        : base[0].toUpperCase() + base.substring(1);
    return AuthUser(id: s.user.id, email: email, displayName: name);
  }
}

/// Sesi autentikasi aktif — null = belum login.
/// Stream Supabase memancarkan event awal + tiap perubahan login/logout.
final sessionProvider = StreamProvider<Session?>((ref) {
  if (!SupabaseService.isConfigured) return const Stream.empty();
  return SupabaseService.client.auth.onAuthStateChange
      .map((e) => e.session)
      .handleError((_) {});
});

/// Versi "data biasa" — UI tinggal cek [AuthUser] atau null.
final authUserProvider = Provider<AuthUser?>((ref) {
  if (!SupabaseService.isConfigured) return null;
  final s = ref.watch(sessionProvider).valueOrNull;
  return s == null ? null : AuthUser.fromSession(s);
});

/// Hasil operasi auth — buat pesan error/sukses di layar login.
class AuthOutcome {
  final bool success;
  final String message;
  const AuthOutcome({required this.success, required this.message});
}

/// Controller: signIn / signUp / signOut via Supabase client.
class AuthController {
  final SupabaseClient? _client;
  AuthController({SupabaseClient? client}) : _client = SupabaseService.isConfigured ? (client ?? SupabaseService.client) : null;

  bool get available => _client != null;

  Future<AuthOutcome> signIn(String email, String password) async {
    if (_client == null) return const AuthOutcome(success: false, message: 'Backend belum terhubung.');
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      if (res.session == null) {
        return const AuthOutcome(
            success: false, message: 'Email belum dikonfirmasi. Cek inbox kamu.');
      }
      return AuthOutcome(success: true, message: 'Selamat datang, ${AuthUser.fromSession(res.session)?.displayName}!');
    } on AuthApiException catch (e) {
      return AuthOutcome(success: false, message: _friendly(e.message));
    } catch (_) {
      return const AuthOutcome(success: false, message: 'Gagal masuk — cek koneksi internet.');
    }
  }

  Future<AuthOutcome> signUp(String email, String password) async {
    if (_client == null) return const AuthOutcome(success: false, message: 'Backend belum terhubung.');
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.session != null) {
        return const AuthOutcome(success: true, message: 'Akun dibuat — kamu langsung masuk.');
      }
      return const AuthOutcome(
          success: true,
          message: 'Akun dibuat! Cek email buat konfirmasi sebelum masuk.');
    } on AuthApiException catch (e) {
      return AuthOutcome(success: false, message: _friendly(e.message));
    } catch (_) {
      return const AuthOutcome(success: false, message: 'Gagal daftar — cek koneksi internet.');
    }
  }

  Future<void> signOut() async {
    if (_client == null) return;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Pesan error Supabase → bahasa awam.
  String _friendly(String? raw) {
    final m = (raw ?? '').toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (m.contains('already registered')) {
      return 'Email ini sudah pernah daftar — silakan masuk saja.';
    }
    if (m.contains('at least 6 characters')) {
      return 'Password minimal 6 karakter.';
    }
    if (m.contains('valid email') || m.contains('invalid email')) {
      return 'Format email tidak benar.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Terlalu sering dicoba — tunggu sebentar.';
    }
    return raw?.isNotEmpty == true ? raw! : 'Terjadi kesalahan. Coba lagi.';
  }
}
