import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/aqi_helper.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import 'detail_screen.dart';

class _BaseMap {
  final String name;
  final String url;
  final List<String> subdomains;
  final String credit;
  const _BaseMap({
    required this.name,
    required this.url,
    required this.subdomains,
    required this.credit,
  });
}

/// 3 basemap gratis tanpa API key (terverifikasi render peta asli).
/// CARTO sengaja TIDAK dipakai: tile-nya sekarang balikin "API KEY REQUIRED".
const _styles = [
  _BaseMap(
    name: 'Humanitarian',
    url: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    subdomains: ['a', 'b'],
    credit: '© OpenStreetMap, gaya HOT',
  ),
  _BaseMap(
    name: 'Standar',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    credit: '© OpenStreetMap',
  ),
  _BaseMap(
    name: 'Satelit',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    subdomains: [],
    credit: '© Esri, Maxar, Earthstar Geographics',
  ),
];

/// Legenda skala AQI (nilai contoh per kategori).
const _legend = [
  (25, 'Baik'),
  (75, 'Sedang'),
  (125, 'Sensitif'),
  (175, 'Tidak Sehat'),
  (250, 'Sangat TH'),
  (350, 'Berbahaya'),
];

/// Peta AQI by area: zona warna per kota + pin + legenda + ganti basemap.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  int _style = 0;

  @override
  Widget build(BuildContext context) {
    final aqi = ref.watch(aqiProvider);
    final favs = ref.watch(favoritesProvider);
    final cities = ref.watch(allCitiesProvider);
    final base = _styles[_style];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Udara'),
        actions: [
          IconButton(
            tooltip: 'Ganti basemap: ${base.name}',
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => setState(() => _style = (_style + 1) % _styles.length),
          ),
        ],
      ),
      body: aqi.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (r) {
          final center = LatLng(r.lat, r.lon);
          final cityList = cities.maybeWhen(
            data: (list) => list
                .where((c) =>
                    (c.lat - r.lat).abs() > 0.3 ||
                    (c.lon - r.lon).abs() > 0.3)
                .toList(),
            orElse: () => const <AirQualityReading>[],
          );
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate: base.url,
                    subdomains: base.subdomains,
                    userAgentPackageName: 'com.hartono.lumair',
                    maxZoom: 19,
                  ),
                  // Zona AQI by area: lingkaran tembus pandang per kota.
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        radius: 60000,
                        useRadiusInMeter: true,
                        color: AqiHelper.color(r.usAqi)
                            .withValues(alpha: 0.22),
                        borderColor:
                            AqiHelper.color(r.usAqi).withValues(alpha: 0.7),
                        borderStrokeWidth: 2,
                      ),
                      for (final c in cityList)
                        CircleMarker(
                          point: LatLng(c.lat, c.lon),
                          radius: 45000,
                          useRadiusInMeter: true,
                          color: AqiHelper.color(c.usAqi)
                              .withValues(alpha: 0.20),
                          borderColor:
                              AqiHelper.color(c.usAqi).withValues(alpha: 0.55),
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 120,
                        height: 84,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AqiHelper.color(r.usAqi),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 6,
                                      color: Colors.black26,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Text('AQI ${r.usAqi}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Icon(Icons.location_on,
                                color: AqiHelper.color(r.usAqi), size: 28),
                          ],
                        ),
                      ),
                      for (final c in cityList)
                        Marker(
                          point: LatLng(c.lat, c.lon),
                          width: 64,
                          height: 48,
                          child: GestureDetector(
                            onTap: () => _openFav(
                              context,
                              FavoritePlace(
                                id:
                                    'city-${c.lat.toStringAsFixed(2)}-${c.lon.toStringAsFixed(2)}',
                                name: c.placeName,
                                lat: c.lat,
                                lon: c.lon,
                                lastAqi: c.usAqi,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AqiHelper.color(c.usAqi),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                          offset: Offset(0, 1)),
                                    ],
                                  ),
                                  child: Text('${c.usAqi}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Icon(Icons.location_on,
                                    color: AqiHelper.color(c.usAqi), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ...favs.map((p) => Marker(
                            point: LatLng(p.lat, p.lon),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _openFav(context, p),
                              child: const Icon(Icons.location_on,
                                  color: Colors.blueGrey, size: 36),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
              // Legenda + kredit + tombol basemap.
              Positioned(
                top: 10,
                right: 10,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('AQI by area',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 3),
                          for (final e in _legend)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AqiHelper.color(e.$1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(e.$2,
                                        style: const TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.my_location,
                            color: AqiHelper.color(r.usAqi)),
                        title: Text(r.placeName),
                        subtitle: Text(
                            'AQI ${r.usAqi} — ${AqiHelper.category(r.usAqi)} • Basemap: ${base.name}'),
                        trailing: TextButton(
                          child: const Text('Detail'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailScreen(reading: r)),
                          ),
                        ),
                      ),
                    ),
                    Text(base.credit,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFav(BuildContext context, FavoritePlace place) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref2, __) {
                final live = ref2.watch(placeAqiProvider(place));
                return live.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Gagal: $e'),
                  data: (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          AqiHelper.color(r.usAqi).withValues(alpha: 0.15),
                      child: Text('${r.usAqi}',
                          style: TextStyle(
                              color: AqiHelper.color(r.usAqi),
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                        'AQI ${r.usAqi} — ${AqiHelper.category(r.usAqi)}'),
                    subtitle: Text(AqiHelper.advice(r.usAqi)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailScreen(reading: r)),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
