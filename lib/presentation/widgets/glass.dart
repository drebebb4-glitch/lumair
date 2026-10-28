import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// Kartu kaca (glassmorphism) — lapisan visual premium LUMAIR.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.09),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Judul screen + 1 kalimat "guna fitur ini" — biar orang awam langsung
/// paham tab buat apa, gak perlu nebak.
class ScreenTitle extends StatelessWidget {
  final String title;
  final String purpose;
  const ScreenTitle({super.key, required this.title, required this.purpose});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        Text(purpose,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
      ],
    );
  }
}

/// Chip kecil bergaya kaca — dipakai buat tag lokasi, suhu, dll.
class GlassChip extends StatelessWidget {  final IconData icon;
  final String label;
  final Color? color;

  const GlassChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFCBD5E1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
