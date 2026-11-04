import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../data/api/articles_api.dart';
import '../../domain/providers.dart';
import '../../domain/models/air_quality.dart';
import '../widgets/glass.dart';
import '../widgets/activity_card.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ArticlesNotifier extends StateNotifier<AsyncValue<ArticlesResult>> {
  final ArticlesApi _api;
  ArticlesNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }

  /// Ambil artikel terbaru dari repo (fallback cache/bawaan saat gagal).
  Future<void> load() async {
    try {
      final r = await _api.load();
      state = AsyncValue.data(r);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final articlesProvider =
    StateNotifierProvider<ArticlesNotifier, AsyncValue<ArticlesResult>>(
        (ref) => ArticlesNotifier(ArticlesApi()));

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Edukasi statis (PRD P0) + kartu live yang nyambung ke AQI user.
/// Artikel hidup dari JSON repo — auto-refresh tiap 5 menit, bisa tarik-kebawah.
class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Poling konten tiap 5 menit selama tab edukasi terbuka.
    _poll = Timer.periodic(const Duration(minutes: 5),
        (_) => ref.read(articlesProvider.notifier).load());
    // Label "terakhir diperbarui" di-refresh tiap menit.
    _tick = Timer.periodic(
        const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  String _rel(DateTime? t) {
    if (t == null) return '—';
    final d = DateTime.now().toUtc().difference(t);
    if (d.inMinutes < 2) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  String _stamp(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final aqi = ref.watch(aqiProvider);
    final articles = ref.watch(articlesProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Image.asset('assets/logo-mark.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                semanticLabel: 'Logo LUMAIR',
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            const SizedBox(width: 10),
            const Expanded(
              child: ScreenTitle(
                title: 'Edukasi Udara',
                purpose: 'Kenapa udara kotor bahaya & cara melindungi diri',
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF0B1220),
        onRefresh: () => ref.read(articlesProvider.notifier).load(),
        child: LayoutBuilder(
          builder: (context, c) {
            final reading =
                aqi.maybeWhen(data: (r) => r, orElse: () => null);
            final live = reading == null
                ? const SizedBox.shrink()
                : _LivePanel(reading: reading);
            final status = _ArticlesStatus(
              result: articles.maybeWhen(data: (a) => a, orElse: () => null),
              loading: articles.isLoading,
              rel: _rel,
              stamp: _stamp,
            );
            final feed = articles.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        color: Color(0xFF94A3B8), size: 36),
                    const SizedBox(height: 10),
                    const Text('Gagal ambil artikel',
                        style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Tarik kebawah buat coba lagi',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              data: (result) => _VariedFeed(result: result),
            );

            // Lanskap: dua panel — kiri kondisi udara, kanan konten.
            if (c.maxWidth > 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          live,
                          const SizedBox(height: 8),
                          _SearchRow(articles: articles),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0x14FFFFFF)),
                  Expanded(
                    flex: 7,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [status, const SizedBox(height: 8), feed],
                    ),
                  ),
                ],
              );
            }

            // Potret: satu kolom penuh.
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                live,
                const SizedBox(height: 8),
                _SearchRow(articles: articles),
                const SizedBox(height: 8),
                status,
                const SizedBox(height: 8),
                feed,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bar status kecil: "Terakhir diperbarui x • auto tiap 5 menit".
class _ArticlesStatus extends StatelessWidget {
  final ArticlesResult? result;
  final bool loading;
  final String Function(DateTime?) rel;
  final String Function(DateTime?) stamp;
  const _ArticlesStatus({
    required this.result,
    this.loading = false,
    required this.rel,
    required this.stamp,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final leading = loading
        ? const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6))
        : Icon(
            r?.fromRemote == true
                ? Icons.cloud_done_outlined
                : Icons.offline_bolt_outlined,
            size: 13,
            color: r?.fromRemote == true
                ? const Color(0xFF34D399)
                : const Color(0xFF94A3B8),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terakhir diperbarui: ${rel(r?.lastModified)}'
              '${stamp(r?.lastModified).isNotEmpty ? " (${stamp(r?.lastModified)})" : ""}'
              ' • unggah ulang otomatis tiap 5 menit',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed bervariasi — bukan kotak seragam
// ---------------------------------------------------------------------------

/// Header User-Agent untuk memuat foto Wikimedia.
const _imgHeaders = {
  'User-Agent': 'LumairApp/1.0 (educational; contact dev@lumair.id)',
};

/// Palet aksen kicker — berputar per urutan artikel agar feed tidak monoton.
const _accentCycle = [
  Color(0xFF10B981), // emerald
  Color(0xFF38BDF8), // sky
  Color(0xFFFBBF24), // amber
  Color(0xFFFB7185), // rose
  Color(0xFFA78BFA), // violet
];

Color _accentFor(int i) => _accentCycle[i % _accentCycle.length];

void _openArticle(BuildContext context, Article a) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ArticleDetail(article: a)),
    );

Widget _netImage(String url, {BoxFit fit = BoxFit.cover}) => Image.network(
      url,
      fit: fit,
      headers: _imgHeaders,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _imgPlaceholder(),
      errorBuilder: (_, __, ___) => _imgPlaceholder(),
    );

Widget _imgPlaceholder() => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12203A), Color(0xFF0B1220)],
        ),
      ),
      alignment: Alignment.center,
      child:
          const Icon(Icons.image_outlined, color: Color(0xFF334155), size: 36),
    );

/// Feed artikel dengan blok berbeda-beda per posisi:
/// [0] hero utama → [1,2] mini → [3] editorial → [4,5] tile kembar
/// → [6] editorial → [7] mini → [8] wide → sisanya mini.
/// List lebih pendek pun aman — tiap cabang memeriksa panjangnya.
class _VariedFeed extends StatelessWidget {
  final ArticlesResult result;
  const _VariedFeed({required this.result});

  @override
  Widget build(BuildContext context) {
    final arts = result.articles;
    final items = <Widget>[];
    var i = 0;
    while (i < arts.length) {
      if (i == 0) {
        // ── HERO: artikel utama, foto full-bleed ──
        items.add(_HeroCard(article: arts[0], accent: _accentFor(0)));
        items.add(const SizedBox(height: 16));
        i++;
      } else if (i == 3 || i == 6) {
        // ── EDITORIAL: kartu teks tanpa foto, gaya kutipan ──
        items.add(_EditorialCard(article: arts[i], accent: _accentFor(i)));
        items.add(const SizedBox(height: 14));
        i++;
      } else if (i == 4 && arts.length >= 6) {
        // ── TILE KEMBAR: dua kartu bersebelahan ──
        items.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _TileCard(article: arts[4], accent: _accentFor(4))),
            const SizedBox(width: 10),
            Expanded(child: _TileCard(article: arts[5], accent: _accentFor(5))),
          ],
        ));
        items.add(const SizedBox(height: 14));
        i += 2;
      } else if (i == 8 && arts.length >= 9) {
        // ── WIDE: kartu lebar dengan foto besar di kiri ──
        items.add(_WideCard(article: arts[8], accent: _accentFor(8)));
        items.add(const SizedBox(height: 14));
        i++;
      } else {
        // ── MINI: kartu horizontal kompak ──
        items.add(_MiniCard(article: arts[i], accent: _accentFor(i)));
        items.add(const SizedBox(height: 12));
        i++;
      }
    }
    items.add(const SizedBox(height: 6));
    items.add(const Text(
      'Artikel dimuat dari repositori LUMAIR. '
      'Foto dokumentasi Wikimedia Commons, sesuai lisensinya masing-masing.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0x59FFFFFF), fontSize: 11),
    ));
    return Column(children: items);
  }
}

/// Kartu utama: foto memenuhi kartu, judul di atas gradasi gelap.
class _HeroCard extends StatelessWidget {
  final Article article;
  final Color accent;
  const _HeroCard({required this.article, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: () => _openArticle(context, article),
        child: SizedBox(
          height: 236,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _netImage(article.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Color(0xE6000000),
                    ],
                    stops: [0.3, 0.62, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('SOROTAN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4)),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(article.kicker,
                        style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6)),
                    const SizedBox(height: 5),
                    Text(article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 4),
                    Text(article.teaser,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu mini horizontal: thumbnail di kiri, teks di kanan.
class _MiniCard extends StatelessWidget {
  final Article article;
  final Color accent;
  const _MiniCard({required this.article, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _openArticle(context, article),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 94,
                  height: 80,
                  child: _netImage(article.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.kicker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: accent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 3),
                    Text(article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25)),
                    const SizedBox(height: 3),
                    Text(article.teaser,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu editorial: tanpa foto, gaya kutipan dengan aksen di kiri.
/// "BACA SELENGKAPNYA" sungguhan: ketuk kartu → isi artikel expand
/// inline dibawah teaser (animasi halus), ketuk lagi → tutup. Dari
/// keadaan terbuka ada pintasan ke halaman detail penuh.
class _EditorialCard extends StatefulWidget {
  final Article article;
  final Color accent;
  const _EditorialCard({required this.article, required this.accent});

  @override
  State<_EditorialCard> createState() => _EditorialCardState();
}

class _EditorialCardState extends State<_EditorialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final accent = widget.accent;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(
              alpha: _expanded ? 0.6 : 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote_rounded, color: accent, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(article.kicker,
                          style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(article.title,
                    style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
                const SizedBox(height: 6),
                Text(article.teaser,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        height: 1.5)),
                // ── ISI_ARTIKEL: dibuka-tutup inline dengan animasi ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              for (final p in article.body) ...[
                                Text(p,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontSize: 13,
                                        height: 1.6)),
                                const SizedBox(height: 6),
                              ],
                              const SizedBox(height: 4),
                              // Pintasan halaman penuh (foto + layout lengkap).
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _openArticle(context, article),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new,
                                        size: 13,
                                        color: accent),
                                    const SizedBox(width: 4),
                                    Text('Buka halaman penuh',
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                        _expanded ? 'TUTUP' : 'BACA SELENGKAPNYA',
                        style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 260),
                      turns: _expanded ? -0.5 : 0,
                      child: Icon(Icons.expand_more,
                          color: accent, size: 16),
                    ),
                    const Spacer(),
                    Text('${article.body.length} paragraf',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile kecil untuk pasangan kolom ganda: foto atas, teks bawah.
class _TileCard extends StatelessWidget {
  final Article article;
  final Color accent;
  const _TileCard({required this.article, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () => _openArticle(context, article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: _netImage(article.image),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.kicker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3)),
                  const SizedBox(height: 4),
                  Text(article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3)),
                  const SizedBox(height: 5),
                  Text(article.teaser,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu lebar: foto besar di kiri (40%), teks di kanan.
class _WideCard extends StatelessWidget {
  final Article article;
  final Color accent;
  const _WideCard({required this.article, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _openArticle(context, article),
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              SizedBox(width: 140, child: _netImage(article.image)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.kicker,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4)),
                      const SizedBox(height: 4),
                      Text(article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25)),
                      const Spacer(),
                      Row(
                        children: [
                          Text('Baca selengkapnya',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: accent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleDetail extends StatelessWidget {
  final Article article;
  const _ArticleDetail({required this.article});  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.kicker)),
      // Layout responsif: landscape → foto & teks bersebelahan
      // (orientation sesuai harapan kontributor UI), portrait → susunan
      // kolom klasik seperti sebelumnya.
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 28),
                    children: [
                      _detailImage(),
                      _detailCredit(),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: _detailContent(),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _detailImage(),
              _detailCredit(),
              ..._contentParts(),
            ],
          );
        },
      ),
    );
  }

  Widget _detailImage() => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            article.image,
            fit: BoxFit.cover,
            headers: _imgHeaders,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0B1220)),
          ),
        ),
      );

  Widget _detailCredit() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(article.credit,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
    );
  }

  List<Widget> _contentParts() {
    return [
      const SizedBox(height: 14),
      Text(article.title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
      const SizedBox(height: 6),
      Text(article.teaser,
          style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500)),
      const Divider(color: Color(0xFF1E293B), height: 32),
      for (final p in article.body) ...[
        Text(p,
            style: const TextStyle(
                fontSize: 15, height: 1.75, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 14),
      ],
      const SizedBox(height: 10),
      const GlassChip(
        icon: Icons.school_outlined,
        label: 'Edukasi LUMAIR',
        color: Color(0xFF94A3B8),
      ),
    ];
  }

  Widget _detailContent() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: _contentParts(),
      );
}

/// Kartu kondisi udara saat ini — ikut mockup edukasi.
class _LivePanel extends StatelessWidget {
  final AirQualityReading reading;
  const _LivePanel({required this.reading});

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final c = AqiHelper.color(r.usAqi);
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UDARA LU SEKARANG',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${r.usAqi}',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: c,
                      height: 1.0)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${AqiHelper.category(r.usAqi)} • ${r.placeName}',
                    style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ActivityCard(aqi: r.usAqi),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: Colors.white.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Pengguna lengkap skala & batas aman ada di artikel bawah',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Baris "Cari informasi, tips, dan panduan lainnya" — buka pencarian artikel.
class _SearchRow extends StatelessWidget {
  final AsyncValue<ArticlesResult> articles;
  const _SearchRow({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openSearch(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: const [
              Icon(Icons.explore_outlined, color: Color(0xFF34D399), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cari informasi, tips, dan panduan lainnya',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 13)),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    final arts = articles.maybeWhen(
        data: (a) => a.articles, orElse: () => const <Article>[]);
    showDialog(
      context: context,
      builder: (_) => _ArticleSearchDialog(articles: arts),
    );
  }
}

/// Dialog pencarian judul artikel — hasil ketuk → halaman detail.
class _ArticleSearchDialog extends StatefulWidget {
  final List<Article> articles;
  const _ArticleSearchDialog({required this.articles});

  @override
  State<_ArticleSearchDialog> createState() => _ArticleSearchDialogState();
}

class _ArticleSearchDialogState extends State<_ArticleSearchDialog> {
  String _q = '';

  List<Article> get _hits {
    final q = _q.toLowerCase().trim();
    if (q.isEmpty) return widget.articles;
    return widget.articles
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.kicker.toLowerCase().contains(q) ||
            a.teaser.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0B1220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cari di Edukasi',
                  style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'mis. PM2.5, masker, AQI…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: _hits.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada artikel yang cocok',
                            style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final a in _hits)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(Icons.article_outlined,
                                  size: 18, color: Color(0xFF34D399)),
                              title: Text(a.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 13.5)),
                              subtitle: Text(a.kicker,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.45),
                                      fontSize: 11)),
                              onTap: () {
                                Navigator.of(context).pop();
                                _openArticle(context, a);
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
