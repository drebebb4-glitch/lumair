import 'package:flutter/material.dart';
import '../../core/aqi_helper.dart';

/// Strip skala US AQI 0–500: 6 segmen warna kategori + penanda posisi nilai.
/// Segment: 0-50, 51-100, 101-150, 151-200 masing-masing 10% lebar;
/// 201-300 20%; 300+ 50% — proporsional terhadap skala asli.
class AqiScaleStrip extends StatelessWidget {
  final int aqi;
  const AqiScaleStrip({super.key, required this.aqi});

  static const _segments = [
    (50, 10.0), // 0-50   → 10%
    (100, 10.0), // 51-100 → 10%
    (150, 10.0), // 101-150→ 10%
    (200, 10.0), // 151-200→ 10%
    (300, 20.0), // 201-300→ 20%
    (500, 50.0), // 300+   → 50%
  ];

  @override
  Widget build(BuildContext context) {
    final frac = (aqi.clamp(0, 500) / 500.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Penanda posisi angka.
        Align(
          alignment: Alignment(frac * 2 - 1, 0), // -1..1
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AqiHelper.color(aqi),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$aqi',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final s in _segments)
                  Expanded(
                    flex: s.$2.toInt(),
                    child: Container(color: AqiHelper.color(s.$1)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.45))),
            Text('skala US AQI 0–500',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.45))),
            Text('500',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.45))),
          ],
        ),
      ],
    );
  }
}
