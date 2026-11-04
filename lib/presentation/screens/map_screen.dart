import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../core/aqi_helper.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import '../widgets/glass.dart';
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
    url:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
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

/// Peta AQI by area — modern: HUD kaca mengambang, kontrol zoom,
/// basemap pills, long-press cek AQI titik mana pun, jadikan beranda.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _map = MapController();
  int _style = 0;
  bool _legendOpen = false;

  // Titik yang long-press (probe) — "cek AQI di titik ini".
  LatLng? _probe;
  String _probeName = 'Menyari nama tempat…';

  void _zoom(double delta) {
    final cam = _map.camera;
    _map.move(cam.center, (cam.zoom + delta).clamp(3.0, 18.0));
  }

  void _recenterTo(LatLng c, {bool zoomIn = false}) {
    _map.move(c, zoomIn ? 9 : _map.camera.zoom.clamp(5.0, 10.0));
  }

  Future<void> _startProbe(LatLng p) async {
    setState(() {
      _probe = p;
      _probeName = 'Menyari nama tempat…';
    });
    // Nama tempat via reverse geocoding (web: gak didukung → fallback koordinat).
    try {
      final marks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (!mounted) return;
      final m = marks.isNotEmpty ? marks.first : null;
      final name = m != null &&
              ((m.locality?.isNotEmpty ?? false) ||
                  (m.administrativeArea?.isNotEmpty ?? false))
          ? [m.locality, m.administrativeArea]
              .where((s) => (s ?? '').isNotEmpty)
              .join(', ')
          : '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}';
      setState(() => _probeName = name);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _probeName = '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}');
      }
    }
  }

  void _clearProbe() => setState(() => _probe = null);

  void _setHome({required String name, required double lat, required double lon}) {
    ref
        .read(homeLocationProvider.notifier)
        .set(HomeOverride(name: name, lat: lat, lon: lon));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Beranda sekarang pakai: $name'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final aqi = ref.watch(aqiProvider);
    final favs = ref.watch(favoritesProvider);
    final cities = ref.watch(allCitiesProvider);
    final base = _styles[_style];
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const ScreenTitle(
          title: 'Peta Udara',
          purpose: 'Geser, zoom, atau long-press titik mana pun',
        ),
        actions: [
          IconButton(
            tooltip: 'Cari kota di peta',
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
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
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 5.5,
                  onLongPress: (_, p) => _startProbe(p),
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
                        color: AqiHelper.color(r.usAqi).withValues(alpha: 0.22),
                        borderColor:
                            AqiHelper.color(r.usAqi).withValues(alpha: 0.7),
                        borderStrokeWidth: 2,
                      ),
                      for (final c in cityList)
                        CircleMarker(
                          point: LatLng(c.lat, c.lon),
                          radius: 45000,
                          useRadiusInMeter: true,
                          color: AqiHelper.color(c.usAqi).withValues(alpha: 0.20),
                          borderColor:
                              AqiHelper.color(c.usAqi).withValues(alpha: 0.55),
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Pin lokasi user — lingkaran berdenyut ala map modern.
                      Marker(
                        point: center,
                        width: 92,
                        height: 92,
                        child: const _PulseDot(),
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
                            child: _AqiBadge(
                              aqi: c.usAqi,
                              small: true,
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
                                  color: Color(0xFF94A3B8), size: 34),
                            ),
                          )),
                      if (_probe != null)
                        Marker(
                          point: _probe!,
                          width: 34,
                          height: 34,
                          child: const _ProbeDot(),
                        ),
                    ],
                  ),
                ],
              ),

              // ── Basemap pills (kiri atas) ──
              Positioned(
                top: 10,
                left: 10,
                child: _GlassPills(
                  labels: [for (final s in _styles) s.name],
                  active: _style,
                  onPick: (i) => setState(() => _style = i),
                ),
              ),

              // ── Legenda (kanan atas, bisa buka-tutup) ──
              Positioned(
                top: 10,
                right: 10,
                child: _LegendPanel(
                  open: _legendOpen,
                  onToggle: () => setState(() => _legendOpen = !_legendOpen),
                ),
              ),

              // ── Kontrol kanan tengah: zoom ±, daftar ikon ──
              Positioned(
                top: 150,
                right: 10,
                child: Column(
                  children: [
                    _MapFab(
                      icon: Icons.add,
                      onTap: () => _zoom(1),
                    ),
                    const SizedBox(height: 6),
                    _MapFab(
                      icon: Icons.remove,
                      onTap: () => _zoom(-1),
                    ),
                    const SizedBox(height: 6),
                    _MapFab(
                      icon: Icons.my_location,
                      onTap: () => _recenterTo(center, zoomIn: true),
                    ),
                  ],
                ),
              ),

              // ── HUD bawah: status udara sekarang / hasil probe ──
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (_probe != null)
                        ? _ProbeHud(
                            point: _probe!,
                            name: _probeName,
                            onClose: _clearProbe,
                          )
                        : _CurrentHud(
                            reading: r,
                            basemapName: base.name,
                            onOpenDetail: () => _openDetail(context, r),
                            onSetHome: () => _setHome(
                                name: r.placeName, lat: r.lat, lon: r.lon),
                          ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(base.credit,
                            style: TextStyle(
                                fontSize: 9.5, color: Colors.grey.shade300)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// AQI live untuk titik probe dihitung di dalam _ProbeHud
  /// (watch placeAqiProvider.FavoritePlace) — gak perlu provider tambahan.

  void _openDetail(BuildContext context, AirQualityReading r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(reading: r)),
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
                  hintText: 'mis. bandung, medan…',
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

// ---------------------------------------------------------------------------
// Komponen kaca mengambang ala peta premium
// ---------------------------------------------------------------------------

class _GlassStack extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;

  const _GlassStack(
      {this.child,
      this.padding = const EdgeInsets.all(10),
      this.radius = 14,
      this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: (accent ?? Colors.white).withValues(alpha: accent != null ? 0.45 : 0.14)),
      ),
      child: child,
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

/// Grup pill glass pilih basemap: [Standar | Satelit | Humanitarian].
class _GlassPills extends StatelessWidget {
  final List<String> labels;
  final int active;
  final ValueChanged<int> onPick;
  const _GlassPills({required this.labels, required this.active, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            const SizedBox(width: 2),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onPick(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: i == active
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: i == active
                            ? const Color(0xFFE2E8F0)
                            : Colors.grey.shade400)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Legenda AQI yang bisa dicompile tutup-buka.
class _LegendPanel extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  const _LegendPanel({required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _GlassStack(
      accent: null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: open
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_list_bulleted,
                          size: 13, color: Color(0xFF94A3B8)),
                      SizedBox(width: 5),
                      Text('Skala AQI',
                          style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                for (final e in _legend)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
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
                        const SizedBox(width: 6),
                        Text(e.$2,
                            style: const TextStyle(
                                color: Color(0xFFCBD5E1), fontSize: 10.5)),
                      ],
                    ),
                  ),
              ],
            )
          : InkWell(
              onTap: onToggle,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_list_bulleted,
                      size: 15, color: Color(0xFF94A3B8)),
                  SizedBox(width: 5),
                  Text('Skala AQI',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
    );
  }
}

/// Pin lokasi user: dot pusat + ring berdenyut (animasi manual,
/// gak pake AnimationController水温 → aman untuk test).
class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399).withValues(alpha: 0.18),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399).withValues(alpha: 0.30),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot probe untuk titik long-press.
class _ProbeDot extends StatelessWidget {
  const _ProbeDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge nilai AQI di atas peta kota.
class _AqiBadge extends StatelessWidget {
  final int aqi;
  final bool small;
  const _AqiBadge({required this.aqi, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 7 : 10, vertical: small ? 2 : 4),
          decoration: BoxDecoration(
            color: AqiHelper.color(aqi),
            borderRadius: BorderRadius.circular(small ? 10 : 14),
            boxShadow: const [
              BoxShadow(blurRadius: 5, color: Colors.black26, offset: Offset(0, 2))
            ],
          ),
          child: Text('AQI $aqi',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: small ? 11 : 13)),
        ),
        Icon(Icons.location_on, color: AqiHelper.color(aqi), size: small ? 20 : 28),
      ],
    );
  }
}

/// HUD bawah — status udara sekarang.
class _CurrentHud extends StatelessWidget {
  final AirQualityReading reading;
  final String basemapName;
  final VoidCallback onOpenDetail;
  final VoidCallback onSetHome;
  const _CurrentHud({
    required this.reading,
    required this.basemapName,
    required this.onOpenDetail,
    required this.onSetHome,
  });

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final c = AqiHelper.color(r.usAqi);
    return _GlassStack(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.withValues(alpha: 0.5)),
                ),
                child: Center(
                    child: Text('${r.usAqi}',
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w800,
                            fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    Text(
                        '${AqiHelper.category(r.usAqi)} • ${AqiHelper.headline(r.usAqi)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSetHome,
                  icon: const Icon(Icons.push_pin_outlined, size: 16),
                  label: const Text('Jadikan Beranda',
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.insights_outlined, size: 16),
                  label: const Text('Detail',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// HUD bawah — hasil probe long-press.
class _ProbeHud extends ConsumerWidget {
  final LatLng point;
  final String name;
  final VoidCallback onClose;
  const _ProbeHud({
    required this.point,
    required this.name,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = FavoritePlace(
      id: 'probe-${point.latitude.toStringAsFixed(4)}-${point.longitude.toStringAsFixed(4)}',
      name: name,
      lat: point.latitude,
      lon: point.longitude,
    );
    final live = ref.watch(placeAqiProvider(place));
    final reading = live.maybeWhen(data: (r) => r, orElse: () => null);
    final c = reading != null ? AqiHelper.color(reading.usAqi) : null;

    return _GlassStack(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c?.withValues(alpha: 0.2) ??
                      Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: c?.withValues(alpha: 0.5) ??
                          Colors.white.withValues(alpha: 0.2)),
                ),
                child: Center(
                    child: reading != null
                        ? Text('${reading.usAqi}',
                            style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w800,
                                fontSize: 14))
                        : const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.travel_explore,
                            size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                    Text(
                        reading != null
                            ? '${AqiHelper.category(reading.usAqi)} • ${AqiHelper.headline(reading.usAqi)}'
                            : 'Lagi ngitung AQI titik ini…',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11)),
                  ],
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 18, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          if (reading != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(homeLocationProvider.notifier).set(HomeOverride(
                          name: name,
                          lat: point.latitude,
                          lon: point.longitude));
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Beranda sekarang pakai: $name'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    icon: const Icon(Icons.push_pin_outlined, size: 16),
                    label: const Text('Jadikan Beranda',
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(reading: reading)),
                    ),
                    icon: const Icon(Icons.insights_outlined, size: 16),
                    label: const Text('Detail',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
