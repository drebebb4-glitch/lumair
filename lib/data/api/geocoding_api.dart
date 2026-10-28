import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../domain/models/air_quality.dart';

/// Cari kota via Geocoding API Open-Meteo (gratis, tanpa key).
class GeocodingApi {
  final http.Client _client;
  GeocodingApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<FavoritePlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final uri = Uri.parse(
      '${AppConstants.geocodingBase}?name=${Uri.encodeComponent(q)}&count=5&language=id&format=json',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Geocoding HTTP ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (json['results'] as List?) ?? [];
    return results.map((e) {
      final m = e as Map<String, dynamic>;
      final name = [
        m['name'],
        m['admin1'],
        m['country'],
      ].where((s) => (s as String?)?.isNotEmpty == true).join(', ');
      return FavoritePlace(
        id: '${m['id']}',
        name: name,
        lat: (m['latitude'] as num).toDouble(),
        lon: (m['longitude'] as num).toDouble(),
      );
    }).toList();
  }
}
