import 'package:flutter/material.dart';
import '../../core/aqi_helper.dart';
import '../../core/app_theme.dart';
import '../../domain/models/air_quality.dart';
import '../widgets/glass.dart';

class _PollutantInfo {
  final String key;
  final String name;
  final double value;
  final String unit;
  final String desc;
  final double warnAt;
  final IconData icon;
  const _PollutantInfo({
    required this.key,
    required this.name,
    required this.value,
    required this.unit,
    required this.desc,
    required this.warnAt,
    required this.icon,
  });
}

/// Detail 6 polutan — kartu kaca, bar gradient, badge dominan menyala.
class DetailScreen extends StatelessWidget {
  final AirQualityReading reading;
  const DetailScreen({super.key, required this.reading});

  List<_PollutantInfo> _items() => [
        _PollutantInfo(
          key: 'pm2_5',
          name: 'PM2.5 (partikel halus)',
          value: reading.pm25,
          unit: 'µg/m³',
          desc: 'Asap halus dari kendaraan, bakar sampah, dan pabrik. Paling berbahaya — bisa nyusup sampai ke dalam paru-paru.',
          warnAt: 35,
          icon: Icons.blur_on,
        ),
        _PollutantInfo(
          key: 'pm10',
          name: 'PM10 (partikel kasar)',
          value: reading.pm10,
          unit: 'µg/m³',
          desc: 'Debu jalan dan asap yang lebih kasar. Bikin hidung & tenggorokan gatel.',
          warnAt: 70,
          icon: Icons.grain,
        ),
        _PollutantInfo(
          key: 'o3',
          name: 'Ozon permukaan (O3)',
          value: reading.o3,
          unit: 'µg/m³',
          desc: 'Muncul pas hari panas + asap kendaraan. Bikin sesak & picu asma — terparah pas siang.',
          warnAt: 100,
          icon: Icons.wb_sunny_outlined,
        ),
        _PollutantInfo(
          key: 'no2',
          name: 'Nitrogen dioksida (NO2)',
          value: reading.no2,
          unit: 'µg/m³',
          desc: 'Gas asap kendaraan & pabrik. Markas polusi ada di jalur yang macet.',
          warnAt: 40,
          icon: Icons.directions_car_outlined,
        ),
        _PollutantInfo(
          key: 'so2',
          name: 'Sulfur dioksida (SO2)',
          value: reading.so2,
          unit: 'µg/m³',
          desc: 'Asap pabrik & pembakaran batu bara. Bau menyengat, bikin sesak napas.',
          warnAt: 40,
          icon: Icons.factory_outlined,
        ),
        _PollutantInfo(
          key: 'co',
          name: 'Karbon monoksida (CO)',
          value: reading.co,
          unit: 'µg/m³',
          desc: 'Gas beracun dari kendaraan & mesin. Gak ada bau — paling bahaya di ruangan tertutup.',
          warnAt: 4000,
          icon: Icons.local_fire_department_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final aqiColor = AqiHelper.color(reading.usAqi);
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(title: Text('Detail • ${reading.placeName}')),
      // Layout responsif (orientation): portrait → ringkasan di atas,
      // kartu polutan menyusul ke bawah. Landscape → ringkasan nempel
      // di kolom kiri (tetap terlihat), daftar polutan jadi kolom kanan,
      // 12 grid pada layar lebar.
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          if (landscape) {
            return Row(
              children: [
                // Kolom kiri: panel konteks — header AQI + kartu "melebihi
                // batas". Kartu mengikuti tinggi konten (bisa diskrol),
                // tidak lagi membentang penuh dengan ruang kosong.
                SizedBox(
                  width: 260,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 24),
                    children: [
                      _summaryCard(aqiColor),
                      const SizedBox(height: AppSpacing.sm),
                      _exceedCard(),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth >= 560;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 24),
                      children: [
                        if (wide)
                          _pollutantsWrap(aqiColor)
                        else
                          ..._pollutantCards(aqiColor),
                      ],
                    );
                  }),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _summaryCard(aqiColor),
              const SizedBox(height: 10),
              ..._pollutantCards(aqiColor),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _pollutantCards(Color aqiColor) => _items()
      .map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _pollutantCard(p, aqiColor),
          ))
      .toList();

  Widget _pollutantsWrap(Color aqiColor) => Wrap(
        runSpacing: AppSpacing.md,
        spacing: AppSpacing.md,
        children: _items()
            .map((p) => SizedBox(
                  width: 260,
                  child: _pollutantCard(p, aqiColor),
                ))
            .toList(),
      );

  /// Kartu ringkasan — angka AQI besar + kategori + chip dominan + saran
  /// aksi dalam bahasa awam (AqiHelper.advice). Dipakai portrait & landscape.
  Widget _summaryCard(Color aqiColor) => GlassCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            aqiColor.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reading.usAqi}',
                style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: aqiColor,
                    height: 1.0,
                    letterSpacing: -1)),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'AQI ${reading.usAqi} — ${AqiHelper.category(reading.usAqi)}',
                style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _dominantChip(aqiColor),
                if (reading.fromCache) _miniChip(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(AqiHelper.advice(reading.usAqi),
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    height: 1.45)),
          ],
        ),
      );

  Widget _dominantChip(Color aqiColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: aqiColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: aqiColor.withValues(alpha: 0.55)),
        ),
        child: Text('Dominan: ${AqiHelper.dominantLabel(reading.dominant)}',
            style: TextStyle(
                color: aqiColor, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _miniChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: const Color(0xFF94A3B8).withValues(alpha: 0.40)),
        ),
        child: const Text('offline',
            style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  /// Kartu "Melebihi batas aman" — daftar polutan yang nilainya di atas
  /// batas beserta rasionya; kolom kiri landscape jadi lebih informatif,
  /// tidak cuma angka AQI besar (Golden Rule 8: kurangi beban memori).
  Widget _exceedCard() {
    final over = _items().where((p) => p.value >= p.warnAt).toList();
    return GlassCard(
      child: over.isEmpty
          ? const Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 16, color: Color(0xFF34D399)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Semua polutan masih dalam batas aman',
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                          height: 1.4)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFF87171)),
                  SizedBox(width: AppSpacing.sm),
                  Text('Melebihi batas aman',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ]),
                const SizedBox(height: AppSpacing.xs),
                for (final p in over)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFE2E8F0), fontSize: 12.5))),
                      Text(
                          '${(p.value / p.warnAt).toStringAsFixed(1)}× batas',
                          style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ],
            ),
    );
  }

  Widget _pollutantCard(_PollutantInfo p, Color aqiColor) {
    final over = p.value >= p.warnAt;
    final ratio = (p.value / p.warnAt).clamp(0.05, 1.0);
    final barColor = over ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final isDominant = reading.dominant == p.key;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: barColor.withValues(alpha: 0.40)),
                ),
                child: Icon(p.icon, color: barColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w600)),
              ),
              if (isDominant)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: aqiColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: aqiColor.withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.blur_on, size: 12, color: aqiColor),
                      const SizedBox(width: 3),
                      Text('DOMINAN',
                          style: TextStyle(
                              color: aqiColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(p.value.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: over
                          ? const Color(0xFFF87171)
                          : const Color(0xFFE2E8F0))),
              const SizedBox(width: 6),
              Text(p.unit,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 12)),
              const Spacer(),
              if (over)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('melebihi batas',
                      style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Bar gradient animasi.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            barColor.withValues(alpha: 0.65),
                            barColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Batas aman ditulis eksplisit + status rasio.
          Row(
            children: [
              Text('Batas aman',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.5)),
              const Spacer(),
              Text('${p.warnAt.toStringAsFixed(0)} ${p.unit}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
              if (over) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                      '${(p.value / p.warnAt).toStringAsFixed(1)}× batas',
                      style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(p.desc,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  height: 1.4)),
        ],
      ),
    );
  }
}
