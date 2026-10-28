import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';

/// Cache 30 menit + dummy fallback (PRD FR-6).
class CacheStore {
  static const _boxName = 'lumair_cache';
  late Box<String> _box;
  bool _ready = false;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _ready = true;
  }

  String _key(double lat, double lon) =>
      '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

  Future<void> saveRaw(double lat, double lon, String rawJson) async {
    if (!_ready) return;
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'raw': rawJson,
    });
    await _box.put(_key(lat, lon), payload);
  }

  /// Kembalikan raw JSON cache bila masih fresh (<30 mnt), else null.
  String? readFreshRaw(double lat, double lon) {
    if (!_ready) return null;
    final payload = _box.get(_key(lat, lon));
    if (payload == null) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final saved = DateTime.parse(map['savedAt'] as String);
      if (DateTime.now().difference(saved).inMinutes <= AppConstants.cacheTtlMinutes) {
        return map['raw'] as String;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> loadDummyJakarta() async {
    final raw = await rootBundle.loadString('assets/dummy/fallback_jakarta.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
