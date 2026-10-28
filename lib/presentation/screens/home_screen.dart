import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../domain/providers.dart';
import '../widgets/aurora_background.dart';
import '../widgets/glass.dart';
import '../widgets/aqi_gauge.dart';
import 'detail_screen.dart';

/// Beranda "LUMAIR Pro": aurora dinamis + gauge animated + kartu kaca.
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
      loading: () => const _StaticShell(child: _Skeleton()),
      error: (e, _) => _StaticShell(
        child: _ErrorCard(message: '$e', onRetry: () {
          ref.invalidate(locationProvider);
        }),
      ),
      data: (r) {
        final color = AqiHelper.color(r.usAqi);
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
                    // ── Header ──
                    SafeArea(
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
                                  colors: [Color(0xFF34D399), Color(0xFF0EA5E9)],
                                ),
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
                            if (r.fromCache)
                              const GlassChip(
                                  icon: Icons.cloud_off_outlined,
                                  label: 'offline'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Gauge utama ──
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
                          const SizedBox(height: 14),
                          AqiGauge(aqi: r.usAqi, color: color),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              AqiHelper.category(r.usAqi),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
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
                                  label:
                                      '${r.temp!.toStringAsFixed(0)}°C',
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
                            'Update ${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
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
                                Text('Rekomendasi',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    )),
                                const SizedBox(height: 3),
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

                    // ── CTA ke detail ──
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
}

/// Kerangka statis (loading/error) — TANPA animasi supaya widget test aman.
class _StaticShell extends StatelessWidget {
  final Widget child;
  const _StaticShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppNight.bg,
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
              const SizedBox(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class AppNight {
  static const bg = Color(0xFF070B14);
}

/// Skeleton loading statis (kaca abu-abu, tanpa timer).
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
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10), width: 16),
                ),
              ),
              const SizedBox(height: 24),
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
