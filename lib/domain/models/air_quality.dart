/// Model inti LUMAIR — sesuai PRD §7.
class AirQualityReading {
  final double lat;
  final double lon;
  final String placeName;
  final DateTime time;
  final int usAqi;
  final double? euAqi;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double so2;
  final double co;
  final double? temp;
  final double? humidity;
  final String dominant;
  final bool fromCache;

  const AirQualityReading({
    required this.lat,
    required this.lon,
    required this.placeName,
    required this.time,
    required this.usAqi,
    this.euAqi,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
    this.temp,
    this.humidity,
    required this.dominant,
    this.fromCache = false,
  });

  factory AirQualityReading.fromOpenMeteo({
    required double lat,
    required double lon,
    required String placeName,
    required Map<String, dynamic> json,
    bool fromCache = false,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final pm25 = (current['pm2_5'] as num?)?.toDouble() ?? 0;
    final pm10 = (current['pm10'] as num?)?.toDouble() ?? 0;
    final o3 = (current['ozone'] as num?)?.toDouble() ?? 0;
    final no2 = (current['nitrogen_dioxide'] as num?)?.toDouble() ?? 0;
    final so2 = (current['sulphur_dioxide'] as num?)?.toDouble() ?? 0;
    final co = (current['carbon_monoxide'] as num?)?.toDouble() ?? 0;

    // Dominan = nilai tertinggi relatif (sederhana untuk prototype).
    final entries = {'pm2_5': pm25, 'pm10': pm10, 'o3': o3, 'no2': no2, 'so2': so2, 'co': co};
    final dominant = entries.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return AirQualityReading(
      lat: lat,
      lon: lon,
      placeName: placeName,
      time: DateTime.tryParse(current['time']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      usAqi: (current['us_aqi'] as num?)?.toInt() ?? 0,
      euAqi: (current['european_aqi'] as num?)?.toDouble(),
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      so2: so2,
      co: co,
      temp: (current['temperature_2m'] as num?)?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      dominant: dominant,
      fromCache: fromCache,
    );
  }
}

class ForecastPoint {
  final DateTime time;
  final int aqi;
  final double pm25;
  const ForecastPoint({required this.time, required this.aqi, required this.pm25});
}

class FavoritePlace {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int? lastAqi;
  final DateTime? updatedAt;
  const FavoritePlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.lastAqi,
    this.updatedAt,
  });
}
