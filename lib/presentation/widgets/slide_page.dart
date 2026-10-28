import 'package:flutter/material.dart';

/// Durasi standar animasi geser antar tab.
const kSlideDuration = Duration(milliseconds: 320);

/// Satu halaman tab. offset: 0 = tampil, -1 = di kiri, 1 = di kanan.
/// Halaman di luar layar tidak digambar, tidak menerima sentuhan, dan
/// animasinya dihentikan, tetapi state-nya tetap hidup (seperti IndexedStack).
class SlidePage extends StatelessWidget {
  const SlidePage({
    super.key,
    required this.offset,
    required this.visible,
    required this.duration,
    required this.child,
  });

  final double offset;
  final bool visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final active = offset == 0;
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: ExcludeSemantics(
          excluding: !active,
          child: IgnorePointer(
            ignoring: !active,
            child: AnimatedSlide(
              offset: Offset(offset, 0),
              duration: duration,
              curve: Curves.easeInOutCubic,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}