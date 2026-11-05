import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../core/cities.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';
import '../widgets/aqi_gauge.dart';
import '../widgets/scale_strip.dart';
import '../widgets/activity_card.dart';
import 'detail_screen.dart';
import 'forecast_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';

/// Beranda LUMAIR 2.0 — pola app modern: hero AQI + skala + aktivitas
/// + banner status + quick actions ke semua fitur.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqi = ref.watch(aqiProvider);
    return aqi.when(
      loading: () => const _StaticShell(
        notice: 'Sebentar ya — lagi ngambil data udara lu…',
        child: _Skeleton(),
      ),
      error: (e, _) => _StaticShell(
        child: _ErrorCard(
            message: '$e',
            onRetry: () {
              ref.invalidate(locationProvider);
            }),
      ),
      data: (r) {
        final color = AqiHelper.color(r.usAqi);
        final loc = ref.watch(locationProvider);
        final gpsFallback =
            loc.maybeWhen(data: (l) => l.isFallback, orElse: () => false);
        final now = DateTime.now();
        final age = now.difference(r.time);
        final status = r.fromCache
            ? (label: 'Offline', color: const Color(0xFF38BDF8))
            : age >= const Duration(hours: 1)
                ? (label: 'Data lama', color: const Color(0xFFFBBF24))
                : (label: 'Live', color: const Color(0xFF34D399));
        final pollutants = _rankPollutants(r);
        final forecast = ref.watch(forecastProvider).maybeWhen(
              data: (points) => points
                  .where((point) => point.time.isAfter(now))
                  .take(6)
                  .toList(),
              orElse: () => const <ForecastPoint>[],
            );
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              AuroraBackground(
                  accent: color, severity: AqiHelper.severity(r.usAqi)),
              RefreshIndicator(
                color: Colors.white,
                backgroundColor: const Color(0xFF0B1220),
                onRefresh: () async {
                  ref.invalidate(locationProvider);
                  await ref.read(aqiProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    if (gpsFallback)
                      _StatusBanner(
                        icon: Icons.location_city_outlined,
                        color: const Color(0xFFFBBF24),
                        text: 'Akses GPS gak aktif — lokasi contoh: '
                            '${r.placeName}. Tap nama lokasi untuk memilih kota.',
                      ),
                    if (r.fromCache) ...[
                      const SizedBox(height: 8),
                      const _StatusBanner(
                        icon: Icons.cloud_off_outlined,
                        color: Color(0xFF38BDF8),
                        text:
                            'Data langsung tidak tersedia. Angka ini data contoh, bukan data tersimpan.',
                      ),
                    ],
                    const SizedBox(height: 14),
                    GlassCard(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.08),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => showLocationPickerSheet(context),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 20, color: Color(0xFFE2E8F0)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.placeName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.expand_more,
                                            size: 20,
                                            color: Colors.white
                                                .withValues(alpha: 0.7)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const _AqiHelpButton(),
                              const SizedBox(width: 8),
                              _StatusBadge(
                                  label: status.label, color: status.color),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _indonesianDate(r.time),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Diukur ${_clockTime(r.time)} • ${_relativeTime(r.time, now)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Colors.white24),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.5)),
                                ),
                                child: Icon(Icons.spa_outlined,
                                    color: color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AQI ${r.usAqi} • ${AqiHelper.category(r.usAqi)}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AqiHelper.headline(r.usAqi),
                                      style: const TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(child: AqiGauge(aqi: r.usAqi, color: color)),
                          const SizedBox(height: 4),
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(1.2),
                            ),
                            child: AqiScaleStrip(aqi: r.usAqi),
                          ),
                          if (pollutants.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: GlassChip(
                                icon: Icons.blur_on,
                                label:
                                    'Dominan ${AqiHelper.dominantLabel(pollutants.first.key)}',
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('CUACA'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _WeatherValue(
                                  icon: Icons.thermostat_outlined,
                                  label: 'Suhu',
                                  value: r.temp == null
                                      ? '—'
                                      : '${r.temp!.toStringAsFixed(1)}°C',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _WeatherValue(
                                  icon: Icons.water_drop_outlined,
                                  label: 'Kelembapan',
                                  value: r.humidity == null
                                      ? '—'
                                      : '${r.humidity!.toStringAsFixed(0)}%',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (pollutants.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _sectionLabel('POLUTAN UTAMA')),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(reading: r)),
                                  ),
                                  child: const Text('Lihat semua',
                                      style: TextStyle(
                                          color: Color(0xFF7DD3FC),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            for (final pollutant in pollutants.take(4))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  children: [
                                    Icon(pollutant.icon,
                                        size: 20,
                                        color: const Color(0xFFCBD5E1)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                          AqiHelper.dominantLabel(
                                              pollutant.key),
                                          style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text(
                                      '${_formatPollutant(pollutant.value)} ${pollutant.unit}',
                                      style: const TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (forecast.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForecastScreen()),
                        ),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _sectionLabel(
                                          'PRAKIRAAN BEBERAPA JAM KE DEPAN')),
                                  const Icon(Icons.arrow_forward,
                                      color: Color(0xFFCBD5E1), size: 18),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: forecast.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final point = forecast[index];
                                    final forecastColor =
                                        AqiHelper.color(point.aqi);
                                    return Container(
                                      width: 82,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: forecastColor.withValues(
                                                alpha: 0.4)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(_clockTime(point.time),
                                              style: const TextStyle(
                                                  color: Color(0xFFCBD5E1),
                                                  fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text('AQI ${point.aqi}',
                                              style: TextStyle(
                                                  color: forecastColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    GlassCard(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.14),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.45)),
                            ),
                            child: Icon(Icons.health_and_safety_outlined,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('REKOMENDASI KESEHATAN'),
                                const SizedBox(height: 4),
                                Text(
                                  AqiHelper.advice(r.usAqi),
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 13.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('AKTIVITAS DI KONDISI INI'),
                          const SizedBox(height: 10),
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(1.27),
                            ),
                            child: ActivityCard(aqi: r.usAqi),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.map_outlined,
                            label: 'Peta',
                            sub: 'Zona AQI kota',
                            color: const Color(0xFF38BDF8),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MapScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.show_chart_outlined,
                            label: 'Prakiraan',
                            sub: '24 jam & 4 hari',
                            color: const Color(0xFFA78BFA),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForecastScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.favorite_border,
                            label: 'Favorit',
                            sub: 'Kota tersimpan',
                            color: const Color(0xFFF472B6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<_HomePollutant> _rankPollutants(AirQualityReading reading) {
  final pollutants = [
    _HomePollutant('pm2_5', reading.pm25, 35, Icons.blur_on),
    _HomePollutant('pm10', reading.pm10, 70, Icons.grain),
    _HomePollutant('o3', reading.o3, 100, Icons.wb_sunny_outlined),
    _HomePollutant('no2', reading.no2, 40, Icons.directions_car_outlined),
    _HomePollutant('so2', reading.so2, 40, Icons.factory_outlined),
    _HomePollutant(
        'co', reading.co, 4000, Icons.local_fire_department_outlined),
  ].where((item) => item.value > 0 && item.value.isFinite).toList()
    ..sort((a, b) => b.safeLimitRatio.compareTo(a.safeLimitRatio));
  return pollutants;
}

String _indonesianDate(DateTime date) {
  const weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} '
      '${months[date.month - 1]} ${date.year}';
}

String _clockTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

String _relativeTime(DateTime date, DateTime now) {
  final minutes = now.difference(date).inMinutes;
  if (minutes < 1) return 'baru saja';
  if (minutes < 60) return '$minutes menit lalu';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours jam lalu';
  return '${hours ~/ 24} hari lalu';
}

String _formatPollutant(double value) =>
    value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

class _HomePollutant {
  final String key;
  final double value;
  final double safeLimit;
  final IconData icon;

  const _HomePollutant(this.key, this.value, this.safeLimit, this.icon);

  double get safeLimitRatio => value / safeLimit;
  String get unit => 'µg/m³';
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _WeatherValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String s) => Text(s,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.72),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ));

/// Tombol "?" → sheet "Apa itu AQI?" dalam bahasa awam.
class _AqiHelpButton extends StatelessWidget {
  const _AqiHelpButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => showAqiHelpSheet(context),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Center(
          child: Text('?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// Sheet penjelasan AQI — bahasa sehari-hari, gak ada jargon.
void showAqiHelpSheet(BuildContext context) {
  const rows = [
    (25, 'Aman buat semua orang'),
    (75, 'Masih oke, sensitif mulai waspada'),
    (125, 'Anak, lansia & asma mulai kena'),
    (175, 'Semua orang mulai kerasa efek'),
    (250, 'Serius — batasi aktivitas keluar'),
    (400, 'Darurat — tetap di dalam ruangan'),
  ];
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0B1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apa itu AQI?',
              style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'AQI = angka 0–500 yang nunjukin seberapa kotor udara yang lu hirup. '
            'Makin TINGGI angkanya = makin KOTOR udaranya.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
                height: 1.45),
          ),
          const SizedBox(height: 14),
          const AqiScaleStrip(aqi: 0), // strip referensi (marker di 0)
          const SizedBox(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AqiHelper.color(r.$1).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AqiHelper.color(r.$1).withValues(alpha: 0.5)),
                    ),
                    child: Text('${r.$1}',
                        style: TextStyle(
                            color: AqiHelper.color(r.$1),
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(r.$2,
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0), fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Sheet "pilih lokasi beranda": GPS sekarang, pencarian kota, 20 kota populer.
void showLocationPickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  List<FavoritePlace> _results = const [];
  bool _searching = false;

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final results = await ref.read(geocodingApiProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
      });
    }
  }

  void _pick(FavoritePlace p) {
    ref.read(homeLocationProvider.notifier).set(
          HomeOverride(name: p.name, lat: p.lat, lon: p.lon),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final override = ref.watch(homeLocationProvider);
    final gps = ref.watch(gpsLocationProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Lokasi Beranda',
                style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Pilihan ini bakal dipakai terus di semua tab sampai lu balikin ke GPS.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
            ),
            const SizedBox(height: 14),

            // ── Lokasi GPS sekarang ("aku sekarang di mana?") ──
            Container(
              decoration: BoxDecoration(
                color: override == null
                    ? const Color(0xFF34D399).withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: override == null
                        ? const Color(0xFF34D399).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.10)),
              ),
              child: ListTile(
                leading: gps.maybeWhen(
                  data: (l) => Icon(
                    l.isFallback
                        ? Icons.location_city_outlined
                        : Icons.gps_fixed,
                    color: override == null
                        ? const Color(0xFF34D399)
                        : const Color(0xFF94A3B8),
                  ),
                  orElse: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                title: Text(
                  gps.maybeWhen(
                    data: (l) => l.isFallback ? '${l.name} (auto)' : l.name,
                    orElse: () => 'Nyari posisi GPS…',
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5),
                ),
                subtitle: gps.maybeWhen(
                  data: (l) => Text(
                    l.isFallback
                        ? 'Sinyal GPS gak aktif — posisi kira-kira ini'
                        : '${l.lat.toStringAsFixed(4)}, ${l.lon.toStringAsFixed(4)}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                trailing: override == null
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF34D399), size: 20)
                    : TextButton(
                        onPressed: () {
                          ref.read(homeLocationProvider.notifier).clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Pakai ini',
                            style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                      ),
                onTap: () {
                  ref.read(homeLocationProvider.notifier).clear();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Search kota ──
            TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: _doSearch,
              decoration: const InputDecoration(
                hintText: 'Cari kota / daerah di seluruh dunia…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_results.isNotEmpty) ...[
              Text('HASIL PENCARIAN',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final p = _results[i];
                    final selected = override != null &&
                        override.lat == p.lat &&
                        override.lon == p.lon;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined,
                          size: 20, color: Color(0xFF94A3B8)),
                      title: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5)),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF34D399), size: 18)
                          : null,
                      onTap: () => _pick(p),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],

            // ── 20 kota besar Indonesia ──
            Text('KOTA BESAR INDONESIA',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in idCities)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => _pick(FavoritePlace(
                            id: 'city_${c.name}',
                            name: c.name,
                            lat: c.lat,
                            lon: c.lon)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Text(c.name,
                              style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatusBanner(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kerangka statis (loading/error) — tanpa timer/animasi → test aman.
class _StaticShell extends StatelessWidget {
  final Widget child;
  final String? notice;
  const _StaticShell({required this.child, this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(notice!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5)),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading statis (scrollable → gak pernah overflow).
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, {double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999),
          ),
        );
    return ListView(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [bar(14, w: 140)]),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10), width: 16),
                ),
              ),
              const SizedBox(height: 22),
              bar(26, w: 120),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(12, w: 90),
              const SizedBox(height: 10),
              bar(14),
              const SizedBox(height: 6),
              bar(14, w: 180),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFFEF4444), size: 44),
            const SizedBox(height: 12),
            const Text('Gagal memuat data udara',
                style: TextStyle(
                    color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
