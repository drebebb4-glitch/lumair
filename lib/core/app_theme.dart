import 'package:flutter/material.dart';

/// LUMAIR design tokens — AI-designed, no Figma.
/// Premium clean: putih + emerald aksen + gold tipis.
class AppTheme {
  static const emerald = Color(0xFF10B981);
  static const gold = Color(0xFFD4AF37);
  static const ink = Color(0xFF0F172A);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Plus Jakarta Sans',
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
      ),
    );
  }
}
