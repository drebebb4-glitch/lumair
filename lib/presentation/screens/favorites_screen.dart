import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../core/constants.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import '../widgets/glass.dart';
import 'detail_screen.dart';

/// Favorit 2.0 — struktur jelas: kota tersimpan dulu, lalu cari,
/// lalu jelajah 20 kota (collapsible). Gak campur aduk lagi.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _ctrl = TextEditingController();
  List<FavoritePlace> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final api = ref.read(geocodingApiProvider);
      final res = await api.search(q);
      setState(() => _results = res);
      if (res.isEmpty) {
        setState(() => _error = 'Tidak ketemu. Coba nama kota lain.');
      }
    } catch (e) {
      setState(() => _error = 'Pencarian gagal (offline?): $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  void _addOrNotice(BuildContext context, FavoritePlace p,
      FavoritesNotifier notifier, WidgetRef ref) {
    if (notifier.contains(p.id)) return;
    if (notifier.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Maksimal 5 favorit — hapus dulu salah satu')));
      return;
    }
    notifier.add(p);
  }

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    final cities = ref.watch(allCitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── 1. Kota tersimpan ──
          _sectionTitle('Kota tersimpan', '(${favs.length}/${AppConstants.maxFavorites})'),
          const SizedBox(height: 6),
          if (favs.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  Icon(Icons.favorite_border,
                      size: 40, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(height: 10),
                  const Text('Belum ada kota tersimpan',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      'Ketuk + pada hasil pencarian di bawah, atau pin di Peta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.5)),
                ],
              ),
            ),
          ...favs.map((p) => _FavTile(place: p)),

          const SizedBox(height: 18),

          // ── 2. Cari kota ──
          _sectionTitle('Cari kota', 'ketik nama kota lalu enter'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'mis. Bandung, Surabaya…',
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 12.5)),
            ),
          ..._results.map((p) {
            final saved = notifier.contains(p.id);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: Text(p.name),
                subtitle: Text(
                    '${p.lat.toStringAsFixed(2)}, ${p.lon.toStringAsFixed(2)}'),
                trailing: saved
                    ? const Icon(Icons.check, color: Color(0xFF34D399))
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            _addOrNotice(context, p, notifier, ref),
                      ),
                onTap: saved
                    ? () => _openFavDetail(context, ref, p)
                    : null,
              ),
            );
          }),

          const SizedBox(height: 18),

          // ── 3. Jelajah 20 kota besar (collapsible) ──
          ExpansionTile(
            collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            collapsedBackgroundColor: Colors.white.withValues(alpha: 0.05),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            leading: const Icon(Icons.public_outlined),
            title: const Text('Jelajah 20 kota besar',
                style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            subtitle: Text('Indonesia — AQI live semua kota',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12)),
            children: [
              cities.when(
                loading: () => const ListTile(
                  leading: SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2)),
                  title: Text('Memuat 20 kota…'),
                ),
                error: (e, _) => ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Gagal memuat (offline)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(allCitiesProvider),
                  ),
                ),
                data: (list) => Column(
                  children: list.map((r) {
                    final c = AqiHelper.color(r.usAqi);
                    final saved = favs.any((p) =>
                        p.name == r.placeName &&
                        (p.lat - r.lat).abs() < 0.01 &&
                        (p.lon - r.lon).abs() < 0.01);
                    final place = FavoritePlace(
                      id: 'city-${r.lat.toStringAsFixed(2)}-${r.lon.toStringAsFixed(2)}',
                      name: r.placeName,
                      lat: r.lat,
                      lon: r.lon,
                      lastAqi: r.usAqi,
                    );
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c.withValues(alpha: 0.15),
                        child: Text('${r.usAqi}',
                            style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      title: Text(r.placeName,
                          style: const TextStyle(
                              color: Color(0xFFE2E8F0), fontSize: 14)),
                      subtitle: Text(AqiHelper.category(r.usAqi),
                          style: TextStyle(color: c, fontSize: 12)),
                      trailing: saved
                          ? const Icon(Icons.check, color: Color(0xFF34D399))
                          : IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _addOrNotice(context, place, notifier, ref),
                            ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailScreen(reading: r)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openFavDetail(
      BuildContext context, WidgetRef ref, FavoritePlace p) async {
    final r = await ref.read(placeAqiProvider(p).future);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(reading: r)),
    );
  }
}

Widget _sectionTitle(String title, String hint) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(width: 8),
        Text(hint,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11.5)),
      ],
    );

class _FavTile extends ConsumerWidget {
  final FavoritePlace place;
  const _FavTile({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(placeAqiProvider(place));
    return Card(
      child: live.when(
        loading: () => ListTile(
          title: Text(place.name,
              style: const TextStyle(color: Color(0xFFE2E8F0))),
          subtitle: Text('Memuat AQI…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          trailing: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => ListTile(
          title: Text(place.name,
              style: const TextStyle(color: Color(0xFFE2E8F0))),
          subtitle: const Text('Gagal memuat',
              style: TextStyle(color: Color(0xFF94A3B8))),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).remove(place.id),
          ),
        ),
        data: (r) {
          final c = AqiHelper.color(r.usAqi);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: c.withValues(alpha: 0.15),
              child: Text('${r.usAqi}',
                  style: TextStyle(
                      color: c, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            title: Text(place.name,
                style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${AqiHelper.category(r.usAqi)}${r.fromCache ? ' • offline' : ''}',
                style: TextStyle(color: c, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).remove(place.id),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DetailScreen(reading: r)),
            ),
          );
        },
      ),
    );
  }
}
