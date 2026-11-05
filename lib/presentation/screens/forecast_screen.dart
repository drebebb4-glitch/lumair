import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../core/app_theme.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import '../widgets/glass.dart';

/// Prakiraan — trend chart interaktif + insight + ringkasan 4 hari.
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String _fmtHour(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(forecastProvider);
    final daily = ref.watch(dailyForecastProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const ScreenTitle(
          title: 'Prakiraan Udara',
          purpose: 'Jawabannya: udara bakal makin buruk atau enggak?',
        ),
      ),
      body: forecast.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Mengambil data dari Open-Meteo…', style: AppTextStyles.hint),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: Color(0xFF94A3B8), size: 36),
                const SizedBox(height: AppSpacing.md),
                const Text('Gagal memuat data prakiraan',
                    style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text('$e',
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(forecastProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return const Center(
                child: Text('Data prakiraan tidak tersedia (offline).'));
          }
          final best = points.reduce((a, b) => a.aqi <= b.aqi ? a : b);
          final worst = points.reduce((a, b) => a.aqi >= b.aqi ? a : b);
          final maxAqi = worst.aqi;
          final maxPm25 =
              points.map((p) => p.pm25).reduce((a, b) => a > b ? a : b);
          final avgFirst =
              points.take(6).map((p) => p.aqi).reduce((a, b) => a + b) /
                  points.take(6).length;
          final avgLast = points
                  .skip(points.length - 6)
                  .map((p) => p.aqi)
                  .reduce((a, b) => a + b) /
              (points.length > 6 ? points.skip(points.length - 6).length : 6);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _InsightBanner(
                points: points,
                best: best,
                worst: worst,
                avgFirst: avgFirst,
                avgLast: avgLast,
              ),
              const SizedBox(height: AppSpacing.md),
              const _AqiInfoAccordion(),
              const SizedBox(height: AppSpacing.md),

              // ── Chart 24 jam ──
              GlassCard(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tren AQI 24 jam ke depan',
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                        'Angka kecil = udara bersih. Garis putus-putus menandai '
                        'batas kategori: 50 (Baik), 100 (Sedang), 150 (Sensitif). '
                        'Sentuh garisnya untuk melihat detail tiap jam.',
                        style: AppTextStyles.hint),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 240,
                      child: _LineChart24(
                          points: points,
                          maxAqi: maxAqi,
                          maxPm25: maxPm25,
                          best: best),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _LegendDots(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Ringkasan 4 hari ──
              daily.maybeWhen(
                data: (days) => days.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ringkasan 4 hari',
                              style: AppTextStyles.sectionTitle),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              for (var i = 0; i < days.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                    child: _DayCard(
                                        day: days[i], hari: _hari, index: i)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                orElse: () => const SizedBox.shrink(),
              ),

              // ── Semua jam: chips menggeser ──
              const Text('PER JAM, 24 JAM KE DEPAN — GESER KE SAMPING',
                  style: AppTextStyles.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              const Text('Angka pada chip = AQI; warnanya mengikuti kategori di sebelah kanan.',
                  style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: points.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = points[i];
                    final c = AqiHelper.color(p.aqi);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(i == 0 ? 'sekarang' : _fmtHour(p.time),
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: i == 0 ? 0.85 : 0.6),
                                  fontSize: 10,
                                  fontWeight: i == 0
                                      ? FontWeight.w700
                                      : FontWeight.w400)),
                          const SizedBox(height: 2),
                          Text('${p.aqi}',
                              style: TextStyle(
                                  color: c,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text(AqiHelper.category(p.aqi),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: c.withValues(alpha: 0.95),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Detail PM2.5 8 jam ke depan ──
              const Text('PM2.5 — PARTIKEL HALUS, 8 JAM KE DEPAN (µg/m³)',
                  style: AppTextStyles.sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                  'PM2.5 adalah partikel paling berbahaya karena bisa masuk ke paru dan darah. Bar makin panjang = makin banyak partikel di udara.',
                  style: AppTextStyles.hint),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                radius: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < points.take(8).length; i++)
                      _PmRow(
                          point: points[i], maxPm25: maxPm25 > 0 ? maxPm25 : 1),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Skala US AQI 0–500 — standar internasional yang juga dipakai '
                'aplikasi kualitas udara global. Prakiraan diperbarui otomatis '
                'setiap kali layar ini dibuka.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu info edukasi buka-tutup — jawaban masukan dosen "tidak informatif":
// pengguna belajar membaca AQI & PM2.5 langsung di halaman (Golden Rule 8,
// mengurangi beban memori), tanpa harus pindah ke halaman Edukasi.
// ---------------------------------------------------------------------------

class _AqiInfoAccordion extends StatefulWidget {
  const _AqiInfoAccordion();

  @override
  State<_AqiInfoAccordion> createState() => _AqiInfoAccordionState();
}

class _AqiInfoAccordionState extends State<_AqiInfoAccordion> {
  static const _ambang = [
    (50, 'Baik', 'Aman bagi semua orang.'),
    (100, 'Sedang', 'Masih aman; kelompok sensitif mulai waspada.'),
    (150, 'Sensitif', 'Anak, lansia & penderita asma batasi outdoor.'),
    (200, 'Tidak Sehat', 'Semua orang berisiko; pakai masker.'),
    (300, 'Sangat Tidak Sehat', 'Sebaiknya tetap di dalam ruangan.'),
    (500, 'Berbahaya', 'Darurat kesehatan — hindari keluar rumah.'),
  ];

  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded,
                    size: 18, color: AppTheme.emerald),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text('Cara membaca halaman ini (AQI & PM2.5)',
                      style: AppTextStyles.sectionTitle),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.expand_more_rounded,
                      color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'AQI adalah indeks kualitas udara skala 0–500: makin besar '
                  'angkanya, makin banyak pencemar di udara dan makin berisiko '
                  'bagi kesehatan.',
                  style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.xs),
                for (final (max, nama, arti) in _ambang)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: AqiHelper.color(max),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$max — $nama: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: arti),
                              ],
                            ),
                            style: AppTextStyles.hint,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'PM2.5 adalah partikel halus berdiameter kurang dari '
                  '2,5 mikron — cukup kecil untuk masuk ke paru hingga aliran '
                  'darah. Panduan WHO: rata-rata tahunan maksimal 15 µg/m³, '
                  'sehingga angka harian di atas 35 µg/m³ tergolong tidak '
                  'sehat. Setiap bar di bawah memakai rental warna yang sama '
                  'dengan kategori AQI agar mudah dikaitkan.',
                  style: AppTextStyles.hint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legenda warna kategori AQI
// ---------------------------------------------------------------------------

/// Deret titik warna + nama kategori — biar warna di grafik langsung kebaca.
class _LegendDots extends StatelessWidget {
  const _LegendDots();

  @override
  Widget build(BuildContext context) {
    final cats = [
      (50, 'Baik'),
      (100, 'Sedang'),
      (150, 'Sensitif'),
      (200, 'Tidak Sehat'),
      (300, 'Sangat Buruk'),
      (500, 'Berbahaya'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final (max, name) in cats)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AqiHelper.color(max),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(name,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9.5)),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart interaktif 24 jam
// ---------------------------------------------------------------------------

class _LineChart24 extends StatelessWidget {
  final List<ForecastPoint> points;
  final int maxAqi;
  final double maxPm25;
  final ForecastPoint best;
  const _LineChart24({
    required this.points,
    required this.maxAqi,
    required this.maxPm25,
    required this.best,
  });

  Widget _hourLabel(ForecastPoint p, {bool bold = false, bool now = false}) =>
      Column(
        children: [
          Text(p.aqi.toString(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: AqiHelper.color(p.aqi))),
          Text(now ? 'sekarang' : ForecastScreen._fmtHour(p.time),
              maxLines: 1,
              style: TextStyle(
                  color: now
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 9.5,
                  fontWeight: now ? FontWeight.w700 : FontWeight.w400)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].aqi.toDouble()),
    ];
    // Skala sumbu Y mengikuti rentang data (bukan 0–500 kaku) supaya tren
    // tidak tampak datar — masukan dosen poin 4. Interval "bulat bagus"
    // agar label sumbu selalu bilangan bulat bersih.
    final yStep = maxAqi <= 20
        ? 5
        : maxAqi <= 60
            ? 10
            : maxAqi <= 120
                ? 25
                : 50;
    final maxY = (((maxAqi * 1.12) / yStep).ceil() * yStep).toDouble();
    final lineColor = AqiHelper.color(best.aqi);

    final lineTouch = LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) => spots.map((s) {
          final i = s.x.toInt();
          if (i < 0 || i >= points.length) return null;
          final p = points[i];
          final c = AqiHelper.color(p.aqi);
          return LineTooltipItem(
            '${ForecastScreen._fmtHour(p.time)}\nAQI ${p.aqi} — ${AqiHelper.category(p.aqi)}\nPM2.5 ${p.pm25.toStringAsFixed(1)} µg/m³',
            TextStyle(
              color: c,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1.4,
            ),
          );
        }).toList(),
      ),
      getTouchedSpotIndicator: (bar, indexes) => indexes.map((i) {
        return TouchedSpotIndicatorData(
          FlLine(color: Colors.white.withValues(alpha: 0.35), strokeWidth: 1),
          FlDotData(
            show: true,
            getDotPainter: (spot, percent, barChartBarData, index) =>
                FlDotCirclePainter(radius: 5, color: Colors.white),
          ),
        );
      }).toList(),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: lineTouch,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            barWidth: 3,
            color: lineColor,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                lineColor.withValues(alpha: 0.35),
                lineColor,
              ],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.28),
                  lineColor.withValues(alpha: 0.02),
                ],
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        betweenBarsData: [],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yStep.toDouble(),
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: yStep.toDouble(),
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Label sumbu X: hanya di 4 posisi dengan jarak seragam (tiap 6 jam
          // data) — masukan dosen poin 2. Titik pertama diberi label "sekarang".
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 6.0,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return _hourLabel(points[i],
                    bold: i == points.length - 1, now: i == 0);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            for (final threshold in [50, 100, 150])
              if (maxY >= threshold)
                HorizontalLine(
                  y: threshold.toDouble(),
                  color: AqiHelper.color(threshold).withValues(alpha: 0.28),
                  strokeWidth: 1,
                  dashArray: [5, 4],
                ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insight banner — nyebutkan jam terbaik & terburuk 24 jam depan
// ---------------------------------------------------------------------------

class _InsightBanner extends StatelessWidget {
  final List<ForecastPoint> points;
  final ForecastPoint best;
  final ForecastPoint worst;
  final double avgFirst;
  final double avgLast;

  const _InsightBanner({
    required this.points,
    required this.best,
    required this.worst,
    required this.avgFirst,
    required this.avgLast,
  });

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  (IconData, String, String, Color) get _trend {
    final diff = avgLast - avgFirst;
    if (diff > 8) {
      return (
        Icons.trending_up,
        'Udara makin buruk',
        'Siapkan masker dan tunda aktivitas luar ruangan.',
        const Color(0xFFF87171)
      );
    }
    if (diff < -8) {
      return (
        Icons.trending_down,
        'Udara makin bersih',
        'Makin lama makin segar — cocok buat agenda luar ruangan.',
        const Color(0xFF34D399)
      );
    }
    return (
      Icons.trending_flat,
      'Cukup stabil',
      'Kondisi hari ini kemungkinan berlanjut sepanjang hari.',
      const Color(0xFFFBBF24)
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _trend;
    final trendColor = t.$4;
    return GlassCard(
      radius: 20,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          trendColor.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(t.$1, color: trendColor, size: 20),
              const SizedBox(width: 8),
              Text(t.$2,
                  style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const Spacer(),
              Text(
                '${avgFirst.toStringAsFixed(0)} → ${avgLast.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(t.$3,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5)),
          const SizedBox(height: 12),
          _RecommendRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Jam terbaik buat keluar:',
            time: _fmt(best.time),
            point: best,
            tail: ' — pas buat olahraga atau urusan luar.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RecommendRow(
            icon: Icons.masks_rounded,
            label: 'Paling kotor sekitar jam',
            time: _fmt(worst.time),
            point: worst,
            tail: ' — kalau bisa, tahan dulu di dalam ruangan.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(AqiHelper.advice(points.first.aqi), style: AppTextStyles.hint),
        ],
      ),
    );
  }
}

/// Satu baris rekomendasi: ikon + teks dengan angka berwarna kategori AQI.
class _RecommendRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final ForecastPoint point;
  final String tail;
  const _RecommendRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.point,
    required this.tail,
  });

  @override
  Widget build(BuildContext context) {
    final c = AqiHelper.color(point.aqi);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                  color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.5),
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                    text: time,
                    style: TextStyle(color: c, fontWeight: FontWeight.w800)),
                TextSpan(text: ' (AQI ${point.aqi}'),
                TextSpan(
                    text: ', ${AqiHelper.category(point.aqi)}',
                    style: TextStyle(color: c)),
                TextSpan(text: ')$tail'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu 4 hari — tint per hari
// ---------------------------------------------------------------------------

class _DayCard extends StatelessWidget {
  final DayForecast day;
  final List<String> hari;
  final int index;
  const _DayCard({required this.day, required this.hari, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = AqiHelper.color(day.maxAqi);
    final label = index == 0 ? 'Hari ini' : hari[day.day.weekday - 1];
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      child: Column(
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                      Colors.white.withValues(alpha: index == 0 ? 0.8 : 0.55),
                  fontSize: 11,
                  fontWeight: index == 0 ? FontWeight.w800 : FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${day.maxAqi}',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          Text(AqiHelper.category(day.maxAqi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c.withValues(alpha: 0.95),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('puncak ${day.peakHour}:00',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10.5)),
        ],
      ),
    );
  }
}

/// Baris kecil PM2.5 per jam — progress bar warna sesuai kategori.
class _PmRow extends StatelessWidget {
  final ForecastPoint point;
  final double maxPm25;
  const _PmRow({required this.point, required this.maxPm25});

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = AqiHelper.color(point.aqi);
    final frac = (point.pm25 / maxPm25).clamp(0.04, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(_fmt(point.time),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(
                    AqiHelper.color(point.aqi).withValues(alpha: 0.75)),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(point.pm25.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 64,
            child: Text(AqiHelper.category(point.aqi),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
