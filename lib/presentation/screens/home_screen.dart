import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../domain/providers.dart';
import 'detail_screen.dart';

/// Beranda: gauge AQI + rekomendasi + jalan ke Detail.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqi = ref.watch(aqiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('LUMAIR')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(locationProvider);
          await ref.read(aqiProvider.future);
        },
        child: aqi.when(
          loading: () => ListView(
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 120),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Gagal memuat: $e')),
              ),
            ],
          ),
          data: (r) {
            final color = AqiHelper.color(r.usAqi);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(r.placeName,
                    style: Theme.of(context).textTheme.titleMedium),
                if (r.fromCache)
                  const Text('Mode offline — data terakhir tersimpan',
                      style: TextStyle(color: Colors.grey)),
                Text(
                  'Update: ${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('${r.usAqi}',
                          style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      Text(
                          'US AQI — ${AqiHelper.category(r.usAqi)}',
                          style: TextStyle(
                              fontSize: 18,
                              color: color,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                          'Dominan: ${AqiHelper.dominantLabel(r.dominant)} • PM2.5 ${r.pm25.toStringAsFixed(1)} µg/m³'),
                      if (r.temp != null)
                        Text(
                            'Suhu ${r.temp!.toStringAsFixed(1)}°C • Lembap ${r.humidity?.toStringAsFixed(0) ?? '-'}%',
                            style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.health_and_safety_outlined),
                    title: const Text('Rekomendasi'),
                    subtitle: Text(AqiHelper.advice(r.usAqi)),
                  ),
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailScreen(reading: r)),
                  ),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Lihat Detail 6 Polutan'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
