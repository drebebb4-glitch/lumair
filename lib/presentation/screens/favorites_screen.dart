import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../core/constants.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import 'detail_screen.dart';

/// Cari kota + simpan favorit (max 5). Tap favorit -> detail AQI live.
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
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final api = ref.read(geocodingApiProvider);
      final res = await api.search(_ctrl.text);
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

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    final cities = ref.watch(allCitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit & Cari Kota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('🌏 AQI Semua Daerah',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          cities.when(
            loading: () => const Card(
              child: ListTile(
                leading: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                title: Text('Memuat 20 kota...'),
              ),
            ),
            error: (e, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: const Text('Gagal memuat kota (offline)'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(allCitiesProvider),
                ),
              ),
            ),
            data: (list) => Column(
              children: list.map((r) {
                final c = AqiHelper.color(r.usAqi);
                final saved = favs.any((p) =>
                    p.name == r.placeName &&
                    (p.lat - r.lat).abs() < 0.01 &&
                    (p.lon - r.lon).abs() < 0.01);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.withValues(alpha: 0.15),
                      child: Text('${r.usAqi}',
                          style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    title: Text(r.placeName),
                    subtitle: Text(AqiHelper.category(r.usAqi)),
                    trailing: saved
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: notifier.isFull
                                ? () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Maksimal ${AppConstants.maxFavorites} favorit')))
                                : () => notifier.add(FavoritePlace(
                                      id:
                                          'city-${r.lat.toStringAsFixed(2)}-${r.lon.toStringAsFixed(2)}',
                                      name: r.placeName,
                                      lat: r.lat,
                                      lon: r.lon,
                                      lastAqi: r.usAqi,
                                    )),
                          ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(reading: r)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('🔍 Cari kota lain',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari kota... mis. Bandung',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  style: TextStyle(color: Colors.red.shade700)),
            ),
          ..._results.map((p) {
            final saved = notifier.contains(p.id);
            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                    '${p.lat.toStringAsFixed(2)}, ${p.lon.toStringAsFixed(2)}'),
                trailing: saved
                    ? const Icon(Icons.check, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: notifier.isFull
                            ? () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Maksimal ${AppConstants.maxFavorites} favorit')))
                            : () => notifier.add(p),
                      ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text('Tersimpan (${favs.length}/${AppConstants.maxFavorites})',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          if (favs.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.favorite_border),
                title: Text('Belum ada favorit'),
                subtitle: Text('Cari kota di atas lalu tekan +'),
              ),
            ),
          ...favs.map((p) => _FavTile(place: p)),
        ],
      ),
    );
  }
}

class _FavTile extends ConsumerWidget {
  final FavoritePlace place;
  const _FavTile({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(placeAqiProvider(place));
    return Card(
      child: live.when(
        loading: () => ListTile(
          title: Text(place.name),
          trailing: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => ListTile(
          title: Text(place.name),
          subtitle: const Text('Gagal memuat'),
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
            title: Text(place.name),
            subtitle: Text(
                '${AqiHelper.category(r.usAqi)}${r.fromCache ? ' • offline' : ''}'),
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
