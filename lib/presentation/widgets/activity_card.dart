import 'package:flutter/material.dart';

/// Kartu "Aktivitas" ala app cuaca: 3 kelompok aktor dengan status
/// Aman / Waspada / Hindari berdasar US AQI.
class ActivityCard extends StatelessWidget {
  final int aqi;
  const ActivityCard({super.key, required this.aqi});

  ({String label, Color color, IconData icon}) _status(int aqi) {
    if (aqi <= 100) {
      return (label: 'Aman', color: const Color(0xFF34D399), icon: Icons.check_circle_outline);
    }
    if (aqi <= 150) {
      return (label: 'Waspada', color: const Color(0xFFFBBF24), icon: Icons.warning_amber_outlined);
    }
    return (label: 'Hindari', color: const Color(0xFFF87171), icon: Icons.block_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.directions_walk_outlined, title: 'Outdoor', hint: _hintOutdoor()),
      (icon: Icons.directions_run, title: 'Olahraga', hint: _hintSport()),
      (icon: Icons.child_care_outlined, title: 'Anak', hint: _hintKids()),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _cell(items[i].icon, items[i].title, items[i].hint)),
        ],
      ],
    );
  }

  Widget _cell(IconData icon, String title, String hint) {
    final s = _status(aqi);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 24),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.icon, size: 12, color: s.color),
              const SizedBox(width: 4),
              Text(s.label,
                  style: TextStyle(
                      color: s.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(hint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9.5,
                  height: 1.2)),
        ],
      ),
    );
  }

  String _hintOutdoor() {
    if (aqi <= 100) return 'Beraktivitas normal';
    if (aqi <= 150) return 'Batasi durasi luar';
    return 'Stay indoor dulu';
  }

  String _hintSport() {
    if (aqi <= 100) return 'Aman outdoor';
    if (aqi <= 150) return 'Persingkat, hindari 10–16';
    return 'Indoor saja';
  }

  String _hintKids() {
    if (aqi <= 100) return 'Aman bermain';
    if (aqi <= 150) return 'Waspada';
    return 'Tetap indoor';
  }
}
