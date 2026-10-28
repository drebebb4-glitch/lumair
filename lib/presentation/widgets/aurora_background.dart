import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Background premium: gradasi gelap + 2 blob aurora bergerak pelan +
/// partikel mengapung (jumlah & warnanya ngikutin level AQI).
class AuroraBackground extends StatefulWidget {
  final Color accent;
  final int severity; // 0..5 → makin parah makin banyak partikel

  const AuroraBackground({
    super.key,
    required this.accent,
    this.severity = 0,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraPainter(
        accent: widget.accent,
        severity: widget.severity,
        t: _ctrl,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Color accent;
  final int severity;
  final Animation<double> t;

  _AuroraPainter({
    required this.accent,
    required this.severity,
    required this.t,
  }) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    // Latar dasar gelap.
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_darken(accent, 0.62), const Color(0xFF070B14)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final phase = t.value * 2 * math.pi;

    // 2 blob aurora yang mengorbit pelan.
    _blob(canvas, size,
        center: Offset(
          size.width * (0.28 + 0.12 * math.sin(phase)),
          size.height * (0.16 + 0.08 * math.cos(phase)),
        ),
        radius: size.width * 0.9,
        color: _lift(accent, 0.34));
    _blob(canvas, size,
        center: Offset(
          size.width * (0.85 + 0.10 * math.cos(phase * 0.8)),
          size.height * (0.52 + 0.10 * math.sin(phase * 0.8)),
        ),
        radius: size.width * 0.75,
        color: _lift(accent, 0.16));

    // Partikel melayang naik — makin parah udara makin banyak & gerah.
    final dots = 8 + severity * 6;
    final dotPaint = Paint()..color = accent.withValues(alpha: 0.20);
    for (var i = 0; i < dots; i++) {
      final golden = i * 2.399963; // golden angle → taburan merata
      final speed = 0.06 + (i % 5) * 0.02;
      final y = size.height *
          (1.1 - ((t.value * speed + (golden % 1.0)) % 1.2));
      final x = size.width * (0.08 + ((golden * 0.37) % 0.86)) +
          size.width * 0.02 * math.sin(phase + i);
      final r = 1.4 + (i % 3) * 0.9;
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }
  }

  void _blob(Canvas canvas, Size size,
      {required Offset center, required double radius, required Color color}) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [color, color.withValues(alpha: 0)],
      );
    canvas.drawCircle(center, radius, paint);
  }

  static Color _lift(Color c, double a) => c.withValues(alpha: a);
  static Color _darken(Color c, double f) => Color.lerp(c, const Color(0xFF070B14), f)!;

  @override
  bool shouldRepaint(_AuroraPainter old) => true;
}
