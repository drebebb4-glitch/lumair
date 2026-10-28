import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
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

  int _severity(int aqi) {
    if (aqi <= 50) return 0;
    if (aqi <= 100) return 1;
    if (aqi <= 150) return 2;
    if (aqi <= 200) return 3;
    if (aqi <= 300) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqi = ref.watch(aqiProvider);
    return aqi.when(
      loading: () => const _StaticShell(
        notice: 'Mengambil lokasi & data udara…',
        child: _Skeleton(),
      ),
      error: (e, _) => _StaticShell(
        child: _ErrorCard(message: '$e', onRetry: () {
          ref.invalidate(locationProvider);
        }),
      ),
      data: (r) {
        final color = AqiHelper.color(r.usAqi);
        final loc = ref.watch(locationProvider);
        final gpsFallback = loc.maybeWhen(data: (l) => l.isFallback, orElse: () => false);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              AuroraBackground(accent: color, severity: _severity(r.usAqi)),
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
                    _header(r.fromCache),
                    const SizedBox(height: 14),

                    // ── Banner status lokasi/internet ──
                    if (gpsFallback)
                      const _StatusBanner(
                        icon: Icons.location_off_outlined,
                        color: Color(0xFFFBBF24),
                        text:
                            'GPS mati/ditolak — memakai Jakarta. Ganti kota di tab Favorit.',
                      ),
                    if (r.fromCache) ...[
                      const SizedBox(height: 8),
                      const _StatusBanner(
                        icon: Icons.cloud_off_outlined,
                        color: Color(0xFF38BDF8),
                        text: 'Mode offline — menampilkan data terakhir tersimpan.',
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── Hero: gauge + skala + kondisi ──
                    GlassCard(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          color.withValues(alpha: 0.07),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.8)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  r.placeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AqiGauge(aqi: r.usAqi, color: color),
                          const SizedBox(height: 4),
                          AqiScaleStrip(aqi: r.usAqi),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassChip(
                                icon: Icons.blur_on,
                                label:
                                    'Dominan ${AqiHelper.dominantLabel(r.dominant)}',
                                color: color,
                              ),
                              if (r.temp != null) ...[
                                const SizedBox(width: 8),
                                GlassChip(
                                  icon: Icons.thermostat_outlined,
                                  label: '${r.temp!.toStringAsFixed(0)}°C',
                                ),
                                const SizedBox(width: 8),
                                GlassChip(
                                  icon: Icons.water_drop_outlined,
                                  label:
                                      '${r.humidity?.toStringAsFixed(0) ?? '-'}%',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update ${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')} • tarik ke bawah untuk refresh',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Aktivitas: outdoor / olahraga / anak ──
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('AKTIVITAS DI KONDISI INI'),
                          const SizedBox(height: 10),
                          ActivityCard(aqi: r.usAqi),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Rekomendasi kesehatan ──
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
                                _sectionLabel('REKOMENDASI'),
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
                    const SizedBox(height: 18),

                    // ── Quick actions ──
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
                              MaterialPageRoute(builder: (_) => const MapScreen()),
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
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(reading: r)),
                      ),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Lihat Detail 6 Polutan'),
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

  Widget _header(bool fromCache) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.air, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'LUMAIR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              if (fromCache)
                const GlassChip(icon: Icons.cloud_off_outlined, label: 'offline'),
            ],
          ),
        ),
      );
}

Widget _sectionLabel(String s) => Text(s,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ));

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatusBanner({required this.icon, required this.color, required this.text});

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
                      fontSize: 10)),
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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF0EA5E9)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.air, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LUMAIR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [bar(14, w: 140)]),
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
