import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/alert_engine.dart';
import '../../domain/models/alert_settings.dart';
import 'location_service.dart';

/// Lokasi yang dipantau oleh peringatan dini.
class MonitoredPlace {
  final String name;
  final double lat;
  final double lon;
  const MonitoredPlace({required this.name, required this.lat, required this.lon});

  /// Format kunci sama dengan CacheStore (2 desimal).
  String get key => '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
}

/// Penyimpanan untuk fitur peringatan dini. Hanya SharedPreferences, jadi
/// aman dipakai dari isolate background (WorkManager) maupun UI.
class AlertStore {
  static const _settingsKey = 'lumair_alert_settings';
  static const _historyKey = 'lumair_alert_history';
  static const _homeKey = 'lumair_alert_home';
  // Sama dengan FavoritesNotifier._key di providers.dart.
  static const _favsKey = 'lumair_favs';

  Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();
    // Isolate background punya cache sendiri; pastikan nilai terbaru.
    await p.reload();
    return p;
  }

  // ---- Settings ----

  Future<AlertSettings> loadSettings() async {
    try {
      final raw = (await _prefs()).getString(_settingsKey);
      if (raw == null) return AlertSettings.defaults;
      return AlertSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AlertSettings.defaults;
    }
  }

  Future<void> saveSettings(AlertSettings s) async {
    try {
      await (await _prefs()).setString(_settingsKey, jsonEncode(s.toJson()));
    } catch (_) {}
  }

  // ---- History (anti-spam) ----

  Future<Map<String, AlertHistoryEntry>> loadHistory() async {
    try {
      final raw = (await _prefs()).getString(_historyKey);
      if (raw == null) return {};
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, AlertHistoryEntry>{};
      m.forEach((k, v) {
        final e = AlertHistoryEntry.fromJson(v);
        if (e != null) out[k] = e;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveHistory(Map<String, AlertHistoryEntry> h) async {
    try {
      await (await _prefs())
          .setString(_historyKey, jsonEncode(h.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
  }

  // ---- Lokasi yang dipantau ----

  /// Dipanggil UI setiap lokasi beranda berubah, supaya background worker
  /// (yang tidak bisa pakai provider/GPS) tahu harus memantau di mana.
  Future<void> saveHome(UserLocation loc) async {
    try {
      await (await _prefs()).setString(
        _homeKey,
        jsonEncode({'name': loc.name, 'lat': loc.lat, 'lon': loc.lon}),
      );
    } catch (_) {}
  }

  MonitoredPlace? _parse(Object? raw) {
    try {
      final m = raw as Map<String, dynamic>;
      return MonitoredPlace(
        name: '${m['name']}',
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lokasi beranda terakhir + favorit.
  /// Duplikat (koordinat sama) digabung.
  Future<List<MonitoredPlace>> loadPlaces({required bool includeFavorites}) async {
    final prefs = await _prefs();
    final out = <String, MonitoredPlace>{};

    void add(MonitoredPlace? p) {
      if (p != null) out.putIfAbsent(p.key, () => p);
    }

    // Snapshot ini sudah hasil resolusi locationProvider (override manual > GPS).
    try {
      final home = prefs.getString(_homeKey);
      if (home != null) add(_parse(jsonDecode(home)));
    } catch (_) {}

    if (includeFavorites) {
      try {
        final raw = prefs.getString(_favsKey);
        if (raw != null) {
          for (final f in jsonDecode(raw) as List) {
            add(_parse(f));
          }
        }
      } catch (_) {}
    }
    return out.values.toList();
  }
}
