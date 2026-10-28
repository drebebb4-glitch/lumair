import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../domain/models/air_quality.dart';

/// Client Open-Meteo Air Quality — tanpa API key (PRD FR-2).
class OpenMeteoApi {
  final http.Client _client;
  OpenMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AirQualityReading> getCurrent({
    required double lat,
    required double lon,
    String placeName = 'Lokasi saya',
  }) async {
    final uri = Uri.parse(
      '${AppConstants.openMeteoBase}?latitude=$lat&longitude=$lon'
      '&current=us_aqi,european_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide,temperature_2m,relative_humidity_2m'
      '&hourly=us_aqi,pm2_5&timezone=auto',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    // Suhu & kelembapan tidak ada di air-quality API -> ambil dari weather API.
    try {
      final wuri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m&timezone=auto',
      );
      final wres = await _client.get(wuri).timeout(const Duration(seconds: 10));
      if (wres.statusCode == 200) {
        final wjson = jsonDecode(wres.body) as Map<String, dynamic>;
        final wcur = wjson['current'] as Map<String, dynamic>?;
        final cur = json['current'] as Map<String, dynamic>;
        if (wcur != null) {
          cur['temperature_2m'] = wcur['temperature_2m'];
          cur['relative_humidity_2m'] = wcur['relative_humidity_2m'];
        }
      }
    } catch (_) {
      // Enrichment opsional — AQI tetap jalan tanpa suhu.
    }
    return AirQualityReading.fromOpenMeteo(
      lat: lat,
      lon: lon,
      placeName: placeName,
      json: json,
    );
  }

  Future<List<ForecastPoint>> getHourly24({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.openMeteoBase}?latitude=$lat&longitude=$lon'
      '&hourly=us_aqi,pm2_5&timezone=auto&forecast_days=2',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Open-Meteo HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final aqis = (hourly['us_aqi'] as List).map((e) => (e as num?)?.toInt() ?? 0).toList();
    final pms = (hourly['pm2_5'] as List).map((e) => (e as num?)?.toDouble() ?? 0).toList();
    final now = DateTime.now();
    final out = <ForecastPoint>[];
    for (var i = 0; i < times.length && out.length < 24; i++) {
      final t = DateTime.tryParse(times[i]) ?? now;
      if (t.isAfter(now.subtract(const Duration(hours: 1)))) {
        out.add(ForecastPoint(time: t, aqi: aqis[i], pm25: pms[i]));
      }
    }
    return out;
  }
}
