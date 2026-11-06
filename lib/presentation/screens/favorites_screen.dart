
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aqi_helper.dart';
import '../../core/constants.dart';
import '../../domain/models/air_quality.dart';
import '../../domain/providers.dart';
import '../widgets/glass.dart';
import 'detail_screen.dart';

/// Favorit 2.2
/// - Potret: Kota tersimpan -> Cari kota -> Jelajah.
/// - Lanskap: dua panel.
/// - Pencarian dibatasi hanya 20 kota dari allCitiesProvider.
/// - Maksimal favorit mengikuti AppConstants.maxFavorites.

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _ctrl = TextEditingController();

  List<FavoritePlace> _results = [];

  bool _searching = false;
  String? _error;

  // Mencegah hasil pencarian lama menimpa hasil terbaru.
  int _requestId = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ============================================================
  // PENCARIAN KOTA
  // Hanya mencari dari 20 kota yang tersedia di allCitiesProvider.
  // ============================================================

  Future<void> _search() async {
    final q = _ctrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _results = [];
        _error = 'Masukkan nama kota terlebih dahulu.';
      });
      return;
    }

    final id = ++_requestId;

    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });

    try {
      // Mengambil daftar kota yang sudah disediakan.
      final cities = await ref.read(allCitiesProvider.future);

      if (!mounted || id != _requestId) return;

      // Pencarian hanya dilakukan pada daftar 20 kota.
      final filteredCities = cities.where((city) {
        return city.placeName.toLowerCase().contains(q);
      }).toList();

      // Mengubah hasil menjadi FavoritePlace.
      final results = filteredCities.map((city) {
        return FavoritePlace(
          id: 'city-${city.lat.toStringAsFixed(2)}-${city.lon.toStringAsFixed(2)}',
          name: city.placeName,
          lat: city.lat,
          lon: city.lon,
          lastAqi: city.usAqi,
        );
      }).toList();

      setState(() {
        _results = results;

        if (results.isEmpty) {
          _error =
              'Kota tidak tersedia. Pilih salah satu dari 20 kota besar.';
        }
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;

      setState(() {
        _error =
            'Gagal memuat daftar kota. Periksa koneksi internet.';
      });
    } finally {
      if (mounted && id == _requestId) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  // ============================================================
  // TAMBAH FAVORIT
  // ============================================================

  void _addOrNotice(
    BuildContext context,
    FavoritePlace p,
    FavoritesNotifier notifier,
    WidgetRef ref,
  ) {
    if (notifier.contains(p.id)) return;

    if (notifier.isFull) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Maksimal 5 favorit — hapus dulu salah satu.',
            ),
          ),
        );
      return;
    }

    notifier.add(p);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${p.name} berhasil ditambahkan ke favorit.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const ScreenTitle(
          title: 'Favorit',
          purpose: 'Pantau kota yang penting buat lu',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth > 620) {
            return _LandscapeBody(state: this);
          }

          return _PortraitBody(state: this);
        },
      ),
    );
  }

  // ============================================================
  // KOTA TERSIMPAN
  // ============================================================

  Widget _savedSection(WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(
          'Kota tersimpan',
          '(${favs.length}/${AppConstants.maxFavorites})',
        ),

        const SizedBox(height: 10),

        if (favs.isEmpty)
          GlassCard(
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Belum ada kota tersimpan',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cari kota di bawah, atau pin di Peta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          )
        else
          ...favs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FavTile(place: p),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CARI KOTA
  // ============================================================

  Widget _searchSection(
    BuildContext context,
    WidgetRef ref,
    FavoritesNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle(
          'Cari kota',
          'pilih dari 20 kota besar',
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari dari 20 kota besar...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _search(),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _requestId++;
                      _results = [];
                      _error = null;
                      _searching = false;
                    });
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            IconButton.filled(
              onPressed: _searching ? null : _search,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontSize: 12.5,
              ),
            ),
          ),

        const SizedBox(height: 8),

        ..._results.map((p) {
          final saved = notifier.contains(p.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CityRowCard(
              leading: const _CityBadge(
                icon: Icons.location_city_outlined,
              ),
              title: p.name,
              subtitle:
                  '${p.lat.toStringAsFixed(2)}, ${p.lon.toStringAsFixed(2)}',
              trailing: saved
                  ? const Icon(
                      Icons.check,
                      color: Color(0xFF34D399),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addOrNotice(
                        context,
                        p,
                        notifier,
                        ref,
                      ),
                    ),
              onTap: saved
                  ? () => _openFavDetail(context, ref, p)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // JELAJAH 20 KOTA BESAR
  // ============================================================

  Widget _exploreSection(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(allCitiesProvider);
    final favs = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);

    return ExpansionTile(
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      collapsedBackgroundColor:
          Colors.white.withValues(alpha: 0.05),
      childrenPadding: const EdgeInsets.only(bottom: 8),

      leading: const Icon(Icons.public_outlined),

      title: const Text(
        'Jelajah 20 kota besar',
        style: TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),

      subtitle: Text(
        'Indonesia — AQI live semua kota',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
        ),
      ),

      children: [
        cities.when(
          loading: () => const ListTile(
            leading: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            title: Text('Memuat 20 kota…'),
          ),

          error: (e, _) => ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Gagal memuat (offline)'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(allCitiesProvider);
              },
            ),
          ),

          data: (list) => Column(
            children: list.map((r) {
              final c = AqiHelper.color(r.usAqi);

              final saved = favs.any(
                (p) =>
                    p.name == r.placeName &&
                    (p.lat - r.lat).abs() < 0.01 &&
                    (p.lon - r.lon).abs() < 0.01,
              );

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
                  child: Text(
                    '${r.usAqi}',
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                title: Text(
                  r.placeName,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                  ),
                ),

                subtitle: Text(
                  AqiHelper.category(r.usAqi),
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                  ),
                ),

                trailing: saved
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF34D399),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addOrNotice(
                          context,
                          place,
                          notifier,
                          ref,
                        ),
                      ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(reading: r),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL KOTA FAVORIT
  // ============================================================

  Future<void> _openFavDetail(
    BuildContext context,
    WidgetRef ref,
    FavoritePlace p,
  ) async {
    try {
      final r = await ref.read(placeAqiProvider(p).future);

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(reading: r),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat detail kualitas udara.'),
        ),
      );
    }
  }
}

// ================================================================
// TAMPILAN POTRET
// ================================================================

class _PortraitBody extends ConsumerWidget {
  final _FavoritesScreenState state;

  const _PortraitBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(favoritesProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        state._savedSection(ref),
        const SizedBox(height: 18),
        state._searchSection(context, ref, notifier),
        const SizedBox(height: 18),
        state._exploreSection(context, ref),
      ],
    );
  }
}

// ================================================================
// TAMPILAN LANDSCAPE
// ================================================================

class _LandscapeBody extends ConsumerWidget {
  final _FavoritesScreenState state;

  const _LandscapeBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(favoritesProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 10, 24),
            child: state._savedSection(ref),
          ),
        ),

        const VerticalDivider(
          width: 1,
          color: Color(0x14FFFFFF),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                state._searchSection(
                  context,
                  ref,
                  notifier,
                ),
                const SizedBox(height: 16),
                state._exploreSection(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// JUDUL BAGIAN
// ================================================================

Widget _sectionTitle(String title, String hint) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        hint,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11.5,
        ),
      ),
    ],
  );
}

// ================================================================
// BADGE AQI
// ================================================================

class _AqiBadge extends StatelessWidget {
  final int aqi;
  final Color color;

  const _AqiBadge({
    required this.aqi,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '$aqi',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ================================================================
// BADGE KOTA
// ================================================================

class _CityBadge extends StatelessWidget {
  final IconData icon;

  const _CityBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.55),
        size: 20,
      ),
    );
  }
}

// ================================================================
// KARTU KOTA
// ================================================================

class _CityRowCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _CityRowCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor ??
                            Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// TILE KOTA FAVORIT
// ================================================================

class _FavTile extends ConsumerWidget {
  final FavoritePlace place;

  const _FavTile({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(placeAqiProvider(place));

    return live.when(
      loading: () => _CityRowCard(
        leading: const _CityBadge(
          icon: Icons.favorite_border,
        ),
        title: place.name,
        subtitle: 'Memuat AQI…',
        trailing: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),

      error: (e, _) => _CityRowCard(
        leading: const _CityBadge(
          icon: Icons.cloud_off_outlined,
        ),
        title: place.name,
        subtitle: 'Gagal memuat',
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            ref.read(favoritesProvider.notifier).remove(place.id);
          },
        ),
      ),

      data: (r) {
        final c = AqiHelper.color(r.usAqi);

        return _CityRowCard(
          leading: _AqiBadge(
            aqi: r.usAqi,
            color: c,
          ),

          title: place.name,

          subtitle:
              '${AqiHelper.category(r.usAqi)}${r.fromCache ? ' • offline' : ''}',

          subtitleColor: c,

          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).remove(place.id);
            },
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(reading: r),
              ),
            );
          },
        );
      },
    );
  }
}
