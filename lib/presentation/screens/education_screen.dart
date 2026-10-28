import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/aqi_helper.dart';
import '../../data/api/articles_api.dart';
import '../../domain/providers.dart';
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
        title: const ScreenTitle(
          title: 'Edukasi Udara',
          purpose: 'Kenapa udara kotor bahaya & cara ngelindungin diri',
        ),
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF0B1220),
        onRefresh: () => ref.read(articlesProvider.notifier).load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Kartu live: konteks AQI user saat ini ──
            aqi.maybeWhen(
              data: (r) {
                final c = AqiHelper.color(r.usAqi);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
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
                              child: Text(
                                  '${AqiHelper.category(r.usAqi)} • ${r.placeName}',
                                  style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ActivityCard(aqi: r.usAqi),
                        const SizedBox(height: 6),
                        Text(
                            'Penjelasan lengkap skala & batas aman ada di artikel bawah.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11.5)),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // ── Status sumber artikel ──
            _ArticlesStatus(
              result: articles.maybeWhen(data: (a) => a, orElse: () => null),
              loading: articles.isLoading,
              rel: _rel,
              stamp: _stamp,
            ),
            const SizedBox(height: 8),

            // ── Daftar artikel ──
            articles.when(
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
              data: (result) => Column(
                children: [
                  for (final a in result.articles) _ArticleCard(article: a),
                  const SizedBox(height: 8),
                  Text(
                    'Artikel dimuat dari repositori LUMAIR. '
                    'Foto dokumentasi Wikimedia Commons, sesuai lisensinya masing-masing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
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

/// Kartu artikel bergaya berita: foto di atas, judul + teaser di bawah.
class _ArticleCard extends StatelessWidget {
  final Article article;
  const _ArticleCard({required this.article});

  static const _headers = {
    'User-Agent': 'LumairApp/1.0 (educational; contact dev@lumair.id)',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ArticleDetail(article: article)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArticleImage(image: article.image),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.kicker,
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6)),
                    const SizedBox(height: 6),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Text(article.teaser,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.45),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Baca selengkapnya',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFF94A3B8)),
                      ],
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

/// Placeholder + fade-in untuk foto artikel.
class _ArticleImage extends StatelessWidget {
  final String image;
  const _ArticleImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        headers: _ArticleCard._headers,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12203A), Color(0xFF0B1220)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined,
            color: Color(0xFF334155), size: 40),
      );
}

class _ArticleDetail extends StatelessWidget {
  final Article article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.kicker)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                headers: _ArticleCard._headers,
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
          ),
          const SizedBox(height: 12),
          Text(article.credit,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
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
          const GlassChip(
            icon: Icons.school_outlined,
            label: 'Edukasi LUMAIR',
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
