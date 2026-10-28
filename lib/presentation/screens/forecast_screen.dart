import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/aqi_helper.dart';
import '../../domain/providers.dart';

/// Prakiraan AQI 24 jam (grafik) — dari Open-Meteo hourly.
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(forecastProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prakiraan 24 Jam')),
      body: forecast.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(
                child: Text('Data prakiraan tidak tersedia (offline).'));
          }
          final spots = [
            for (var i = 0; i < points.length; i++)
              FlSpot(i.toDouble(), points[i].aqi.toDouble()),
          ];
          final maxAqi =
              points.map((p) => p.aqi).reduce((a, b) => a > b ? a : b);
          final hourFmt = DateFormat.Hm();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tren AQI 24 jam ke depan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: (maxAqi * 1.25).clamp(60, 500).toDouble(),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 3,
                                color: Colors.teal,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      Colors.teal.withValues(alpha: 0.15),
                                ),
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 5,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= points.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        hourFmt.format(points[i].time),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...points.take(8).map((p) {
                final c = AqiHelper.color(p.aqi);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.withValues(alpha: 0.15),
                      child: Text('${p.aqi}',
                          style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    title: Text(hourFmt.format(p.time)),
                    subtitle: Text('PM2.5 ${p.pm25.toStringAsFixed(1)} µg/m³'),
                    trailing: Text(AqiHelper.category(p.aqi),
                        style: TextStyle(color: c)),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
