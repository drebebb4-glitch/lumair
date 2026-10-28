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
            tooltip: 'Cari kota di peta',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
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
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name,
                style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref2, __) {
                final live = ref2.watch(placeAqiProvider(place));
                return live.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF34D399))),
                  error: (e, _) => Text('Gagal: $e',
                      style: const TextStyle(color: Color(0xFF94A3B8))),
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
                        'AQI ${r.usAqi} — ${AqiHelper.category(r.usAqi)}',
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(AqiHelper.advice(r.usAqi),
                        style: const TextStyle(color: Color(0xFF94A3B8))),
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

  /// Sheet pencarian kota → hasil langsung bisa dibuka detail AQI-nya.
  void _openSearch(BuildContext context) {
    final ctrl = TextEditingController();
    List<FavoritePlace> results = [];
    String? error;
    bool searching = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text('Cari kota',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) async {
                  final q = ctrl.text.trim();
                  if (q.isEmpty) return;
                  setSheet(() => searching = true);
                  try {
                    final res =
                        await ref.read(geocodingApiProvider).search(q);
                    setSheet(() {
                      results = res;
                      searching = false;
                      error = res.isEmpty
                          ? 'Tidak ketemu. Coba nama kota lain.'
                          : null;
                    });
                  } catch (e) {
                    setSheet(() {
                      searching = false;
                      error = 'Pencarian gagal (offline?)';
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'mis. Bandung, Medan…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              if (searching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF34D399))),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!,
                      style: const TextStyle(
                          color: Color(0xFFF87171), fontSize: 12.5)),
                ),
              ...results.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_city_outlined,
                        color: Color(0xFF94A3B8)),
                    title: Text(p.name,
                        style: const TextStyle(color: Color(0xFFE2E8F0))),
                    subtitle: Text(
                        '${p.lat.toStringAsFixed(2)}, ${p.lon.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF64748B)),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      try {
                        final r = await ref
                            .read(placeAqiProvider(p).future);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailScreen(reading: r)),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Gagal memuat AQI kota (offline?)')),
                        );
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
