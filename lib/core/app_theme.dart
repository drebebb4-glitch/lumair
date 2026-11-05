import 'package:flutter/material.dart';

/// LUMAIR design tokens — AI-designed, no Figma.
/// "LUMAIR Pro": dark premium, aksen dinamis per level AQI.
class AppTheme {
  static const emerald = Color(0xFF10B981);
  static const gold = Color(0xFFD4AF37);
  static const ink = Color(0xFF0F172A); // teks di atas terang (legacy)
  static const night = Color(0xFF070B14); // latar gelap utama
  static const nightSurface = Color(0xFF0B1220); // navbar / panel

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: night,
      fontFamily: 'Plus Jakarta Sans',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
        bodySmall: TextStyle(color: Color(0xFF94A3B8)),
        titleMedium: TextStyle(color: Color(0xFFE2E8F0)),
        titleLarge: TextStyle(color: Color(0xFFE2E8F0)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF94A3B8),
        titleTextStyle: TextStyle(
            color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600, fontSize: 15),
        subtitleTextStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE2E8F0),
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emerald, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: nightSurface,
        contentTextStyle: const TextStyle(color: Color(0xFFE2E8F0)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Alias lama (dipakai main.dart sebelum makeover) — sekarang gelap premium.
  static ThemeData get light => dark;
}

/// Spacing token — skala grid 4 pt. Satu-satunya sumber jarak antar elemen
/// agar rhythm halaman konsisten (masukan dosen: spacing belum diatur).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
}

/// Type scale halaman Prakiraan — ukuran & bobot terbatas (tidak acak),
/// kontras teks sekunder dijaga slate #94A3B8, bukan putih transparan rendah.
class AppTextStyles {
  /// Judul besar bagian atas banner/hero.
  static const TextStyle h1 = TextStyle(
      color: Color(0xFFE2E8F0),
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.25);

  /// Judul tiap section/card.
  static const TextStyle sectionTitle = TextStyle(
      color: Color(0xFFE2E8F0),
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.35);

  /// Heading kecil huruf kapital (label grup chips/bar).
  static const TextStyle sectionLabel = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      height: 1.4);

  /// Teks isi utama.
  static const TextStyle body = TextStyle(
      color: Color(0xFFE2E8F0),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.5);

  /// Penjelasan pembantu / keterangan.
  static const TextStyle hint = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.45);

  /// Keterangan kecil (footer, catatan sumber).
  static const TextStyle caption = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.4);
}
