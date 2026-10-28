import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/cities.dart';
import '../core/constants.dart';
import '../data/api/geocoding_api.dart';
import '../data/api/openmeteo_api.dart';
import '../data/services/location_service.dart';
import 'models/air_quality.dart';

/// Lokasi user: override manual (kalau ada), else GPS / fallback Jakarta.
final locationProvider = FutureProvider<UserLocation>((ref) async {
  final ov = ref.watch(homeLocationProvider);
  if (ov != null) {
    return UserLocation(lat: ov.lat, lon: ov.lon, name: ov.name);
  }
  return ref.watch(gpsLocationProvider.future);
});

/// GPS mentah — selalu dihitung, terpisah dari override beranda.
final gpsLocationProvider = FutureProvider<UserLocation>((_) async {
  return LocationService().current();
});
/// Lokasi beranda yang dipilih manual (persisten).
/// Null = belum pernah dipilih → otomatis pakai GPS.
class HomeOverride {
  final String name;
  final double lat;
  final double lon;
  const HomeOverride({required this.name, required this.lat, required this.lon});
}

class HomeLocationNotifier extends StateNotifier<HomeOverride?> {
  static const _key = 'lumair_home_override';
  HomeLocationNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = HomeOverride(
        name: '${m['name']}',
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = state;
      if (s == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(
            _key, jsonEncode({'name': s.name, 'lat': s.lat, 'lon': s.lon}));
      }
    } catch (_) {}
  }

  Future<void> set(HomeOverride o) async {
    state = o;
    await _save();
  }

  Future<void> clear() async {
    state = null;
    await _save();
  }
}

final homeLocationProvider =
    StateNotifierProvider<HomeLocationNotifier, HomeOverride?>(
        (ref) => HomeLocationNotifier());

/// AQI lokasi user. Tidak pernah error ke UI: gagal API -> dummy offline.
final aqiProvider = FutureProvider<AirQualityReading>((ref) async {
  final loc = await ref.watch(locationProvider.future);
  try {
    return await OpenMeteoApi().getCurrent(
      lat: loc.lat,
      lon: loc.lon,
      placeName: loc.name,
    );
  } catch (_) {
    return _dummyReading(loc);
  }
});

/// Prakiraan 24 jam. Gagal -> list kosong.
final forecastProvider = FutureProvider<List<ForecastPoint>>((ref) async {
  final loc = await ref.watch(locationProvider.future);
  try {
    return await OpenMeteoApi().getHourly24(lat: loc.lat, lon: loc.lon);
  } catch (_) {
    return <ForecastPoint>[];
  }
});

/// Ringkasan 4 hari. Gagal -> list kosong.
final dailyForecastProvider = FutureProvider<List<DayForecast>>((ref) async {
  final loc = await ref.watch(locationProvider.future);
  try {
    return await OpenMeteoApi().getDaily4(lat: loc.lat, lon: loc.lon);
  } catch (_) {
    return <DayForecast>[];
  }
});

/// AQI satu tempat favorit (on-demand).
final placeAqiProvider =
    FutureProvider.family<AirQualityReading, FavoritePlace>((ref, place) async {
  try {
    return await OpenMeteoApi().getCurrent(
      lat: place.lat,
      lon: place.lon,
      placeName: place.name,
    );
  } catch (_) {
    return _dummyReadingPlace(place);
  }
});

/// AQI 20 kota besar sekaligus (paralel). Kota gagal fetch dilewati.
final allCitiesProvider = FutureProvider<List<AirQualityReading>>((ref) async {
  final api = OpenMeteoApi();
  final results = await Future.wait([
    for (final c in idCities) _fetchCity(api, c),
  ]);
  return results.whereType<AirQualityReading>().toList();
});

Future<AirQualityReading?> _fetchCity(OpenMeteoApi api, IdCity city) async {
  try {
    return await api.getCurrent(
      lat: city.lat,
      lon: city.lon,
      placeName: city.name,
    );
  } catch (_) {
    return null;
  }
}

AirQualityReading _dummyReading(UserLocation loc) {
  return AirQualityReading(
    lat: loc.lat,
    lon: loc.lon,
    placeName: loc.isFallback ? AppConstants.fallbackName : loc.name,
    time: DateTime.now(),
    usAqi: 128,
    euAqi: 62,
    pm25: 46.5,
    pm10: 68.2,
    o3: 42.0,
    no2: 28.4,
    so2: 8.1,
    co: 520.0,
    temp: 31.2,
    humidity: 72,
    dominant: 'pm2_5',
    fromCache: true,
  );
}

AirQualityReading _dummyReadingPlace(FavoritePlace place) {
  return AirQualityReading(
    lat: place.lat,
    lon: place.lon,
    placeName: place.name,
    time: DateTime.now(),
    usAqi: place.lastAqi ?? 80,
    pm25: 28.0,
    pm10: 42.0,
    o3: 35.0,
    no2: 18.0,
    so2: 6.0,
    co: 320.0,
    dominant: 'pm2_5',
    fromCache: true,
  );
}

// ---- Favorit (SharedPreferences, max 5) ----

class FavoritesNotifier extends StateNotifier<List<FavoritePlace>> {
  static const _key = 'lumair_favs';
  FavoritesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      state = list
          .map((m) => FavoritePlace(
                id: '${m['id']}',
                name: '${m['name']}',
                lat: (m['lat'] as num).toDouble(),
                lon: (m['lon'] as num).toDouble(),
                lastAqi: (m['lastAqi'] as num?)?.toInt(),
              ))
          .toList();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'lat': p.lat,
                'lon': p.lon,
                'lastAqi': p.lastAqi,
              })
          .toList()),
    );
    } catch (_) {}
  }

  bool get isFull => state.length >= AppConstants.maxFavorites;
  bool contains(String id) => state.any((p) => p.id == id);

  Future<void> add(FavoritePlace place) async {
    if (contains(place.id) || isFull) return;
    state = [...state, place];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<FavoritePlace>>(
        (ref) => FavoritesNotifier());

final geocodingApiProvider = Provider<GeocodingApi>((ref) => GeocodingApi());
