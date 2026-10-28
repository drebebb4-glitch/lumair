import 'package:flutter/material.dart';
import '../../core/aqi_helper.dart';
import '../../domain/models/air_quality.dart';

class _PollutantInfo {
  final String key;
  final String name;
  final double value;
  final String unit;
  final String desc;
  final double warnAt;
  const _PollutantInfo({
    required this.key,
    required this.name,
    required this.value,
    required this.unit,
    required this.desc,
    required this.warnAt,
  });
}

/// Detail 6 polutan + penjelasan sumber & risiko.
class DetailScreen extends StatelessWidget {
  final AirQualityReading reading;
  const DetailScreen({super.key, required this.reading});

  List<_PollutantInfo> _items() => [
        _PollutantInfo(
          key: 'pm2_5',
          name: 'PM2.5 (partikel halus)',
          value: reading.pm25,
          unit: 'µg/m³',
          desc: 'Partikel <2,5µm dari kendaraan, bakar sampah & industri. Masuk hingga alveoli paru. Paling berbahaya.',
          warnAt: 35,
        ),
        _PollutantInfo(
          key: 'pm10',
          name: 'PM10 (partikel kasar)',
          value: reading.pm10,
          unit: 'µg/m³',
          desc: 'Debu jalan, konstruksi & asap. Mengiritasi hidung, tenggorokan, dan mata.',
          warnAt: 70,
        ),
        _PollutantInfo(
          key: 'o3',
          name: 'Ozon permukaan (O3)',
          value: reading.o3,
          unit: 'µg/m³',
          desc: 'Terbentuk dari reaksi sinar matahari + gas kendaraan. Memicu asma & sesak, puncaknya siang hari.',
          warnAt: 100,
        ),
        _PollutantInfo(
          key: 'no2',
          name: 'Nitrogen dioksida (NO2)',
          value: reading.no2,
          unit: 'µg/m³',
          desc: 'Gas buang kendaraan & pembangkit. Sumber utama polusi koridor macet kota.',
          warnAt: 40,
        ),
        _PollutantInfo(
          key: 'so2',
          name: 'Sulfur dioksida (SO2)',
          value: reading.so2,
          unit: 'µg/m³',
          desc: 'Pembakaran batu bara & industri. Bau menyengat, hujan asam, sesak napas.',
          warnAt: 40,
        ),
        _PollutantInfo(
          key: 'co',
          name: 'Karbon monoksida (CO)',
          value: reading.co,
          unit: 'µg/m³',
          desc: 'Pembakaran tak sempurna (macet, genset). Mengikat oksigen darah; bahaya di ruang tertutup.',
          warnAt: 4000,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final aqiColor = AqiHelper.color(reading.usAqi);
    return Scaffold(
      appBar: AppBar(title: Text('Detail • ${reading.placeName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: aqiColor,
                child: Text('${reading.usAqi}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text('AQI ${reading.usAqi} — ${AqiHelper.category(reading.usAqi)}'),
              subtitle: Text(
                  'Dominan: ${AqiHelper.dominantLabel(reading.dominant)}${reading.fromCache ? ' • offline' : ''}'),
            ),
          ),
          const SizedBox(height: 8),
          ..._items().map((p) {
            final over = p.value >= p.warnAt;
            final ratio = (p.value / p.warnAt).clamp(0.05, 1.0);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (reading.dominant == p.key)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: aqiColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('dominan',
                                style: TextStyle(
                                    color: aqiColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${p.value.toStringAsFixed(1)} ${p.unit}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: over ? Colors.red.shade700 : null)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            over ? Colors.red : Colors.green),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(p.desc,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
