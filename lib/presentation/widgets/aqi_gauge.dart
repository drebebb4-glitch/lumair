import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Gauge AQI melingkar: ring gradient nge-sweep 0→nilai, angka count-up,
/// glow pulse lembut. Semua gerakan cuma jalan di state data.
class AqiGauge extends StatefulWidget {
  final int aqi;
  final Color color;
  final double size;

  const AqiGauge({
    super.key,
    required this.aqi,
    required this.color,
    this.size = 240,
  });

  @override
  State<AqiGauge> createState() => _AqiGaugeState();
}

class _AqiGaugeState extends State<AqiGauge> with TickerProviderStateMixin {
  late final AnimationController _sweep; // gerakan ring + count-up (1x)
  late final AnimationController _pulse; // glow bernapas (repeat)

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _sweep.forward();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = CurvedAnimation(parent: _sweep, curve: Curves.easeOutCubic);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([eased, _pulse]),
        builder: (context, _) {
          final count = (eased.value * widget.aqi).round();
          return CustomPaint(
            painter: _GaugePainter(
              progress: eased.value,
              color: widget.color,
              glow: _pulse.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count',
                      style: TextStyle(
                        fontSize: widget.size * 0.26,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      )),
                  const SizedBox(height: 2),
                  Text('US AQI',
                      style: TextStyle(
                        fontSize: widget.size * 0.062,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 3,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glow;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.glow,
  });

  static const _start = -3 * math.pi / 4; // 135° (kiri-bawah)
  static const _total = 3 * math.pi / 2; // sweep 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;

    // Track gelap.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _total,
      false,
      track,
    );

    // Glow bernapas di belakang ring nilai.
    final sweep = _total * progress.clamp(0.02, 1.0);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.28 + 0.22 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      sweep,
      false,
      glowPaint,
    );

    // Ring nilai dengan gradient sepanjang lengkungan.
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        [color.withValues(alpha: 0.75), color, color],
        [0.0, 0.85, 1.0],
        TileMode.clamp,
        _start,
        _start + sweep,
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      sweep,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.glow != glow || old.color != color;
}
