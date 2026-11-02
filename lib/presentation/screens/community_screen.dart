import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/auth_provider.dart';
import '../../domain/providers.dart';
import '../../domain/report_provider.dart';
import '../widgets/glass.dart';
import 'auth_screen.dart';

/// Tab Komunitas LUMAIR — laporan banjir & penutupan jalan.
/// Struktur: gate (backend/akun) → feed laporan terbaru + FAB
/// "Lapor" yang membuka sheet form. Setiap orang boleh mengirim
/// laporan berulang kali; hanya milik sendiri yang bisa dihapus.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseService.isConfigured) {
      return const _ScreenFrame(
        title: 'Laporan Komunitas',
        subtitle: 'Lapor banjir & jalan ditutup agar tetangga tahu dulu lancar',
        child: _NotConfiguredView(),
      );
    }
    final user = ref.watch(authUserProvider);
    if (user == null) {
      return _ScreenFrame(
        title: 'Laporan Komunitas',
        subtitle: 'Lapor banjir & jalan ditutup agar tetangga tahu dulu lancar',
        child: _LoginGateView(onLogin: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }),
      );
    }
    return const _ReportBody();
  }
}

/// Kerangka layar senada dengan tab-tab lain (judul + konten).
class _ScreenFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ScreenFrame(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(title: title, purpose: subtitle),
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConfiguredView extends StatelessWidget {
  const _NotConfiguredView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_sync_outlined,
                color: Color(0xFFFBBF24), size: 42),
            const SizedBox(height: 10),
            const Text('Belum terhubung ke backend',
                style: TextStyle(
                    color: Color(0xFFE2E8F0), fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Laporan butuh kredensial Supabase via --dart-define. '
              'Lihat panduan di README repo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginGateView extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginGateView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF38BDF8), size: 40),
              const SizedBox(height: 10),
              const Text('Laporan butuh akun',
                  style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 6),
              const Text(
                'Supaya setiap laporan punya pemilik yang jelas, '
                'masuk (atau daftar) dulu yuk — gratis, cuma email + password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login_outlined),
                label: const Text('Masuk / Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feed + FAB laporan utama — hanya untuk user yang sudah login.
class _ReportBody extends ConsumerWidget {
  const _ReportBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsProvider);
            await ref.read(reportsProvider.future);
          },
          child: reports.when(
            loading: () => const _SoftLoading(),
            error: (e, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_outlined,
                            color: Color(0xFFEF4444), size: 38),
                        const SizedBox(height: 10),
                        const Text('Gagal memuat laporan',
                            style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => ref.invalidate(reportsProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            data: (list) => list.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 70, 20, 0),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  color: Color(0xFF64748B), size: 40),
                              SizedBox(height: 10),
                              Text('Belum ada laporan',
                                  style: TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 6),
                              Text(
                                'Jadi orang pertama! Ketuk tombol + di bawah '
                                'untuk melapor banjir atau jalan ditutup.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12.5,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final r = list[i];
                      final user = ref.watch(authUserProvider);
                      final mine = user?.id == r.userId;
                      return _ReportTile(
                        entry: r,
                        mine: mine,
                        onDelete: mine
                            ? () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF0B1220),
                                    title: const Text('Hapus laporan ini?',
                                        style: TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 16)),
                                    content: const Text(
                                        'Laporkan hanya bisa dihapus oleh '
                                        'kamu (pemilik laporannya).',
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal',
                                            style: TextStyle(
                                                color: Color(0xFF94A3B8))),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus',
                                            style: TextStyle(
                                                color: Color(0xFFEF4444))),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  final deleted =
                                      await ref.read(reportsControllerProvider).delete(r.id);
                                  if (!ctx.mounted) return;
                                  if (!deleted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Gagal hapus — coba lagi.')),
                                    );
                                  }
                                }
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ),
        // ── FAB besar: lapor!
        Positioned(
          right: 0,
          bottom: 8,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF34D399),
            foregroundColor: const Color(0xFF06111F),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Lapor',
                style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () => _openReportSheet(context, ref),
          ),
        ),
      ],
    );
  }

  void _openReportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReportFormSheet(),
    );
  }
}

/// FAB lapor bertumpu di controller provider — biar bisa di-test.
final reportsControllerProvider = Provider<ReportsController>((ref) {
  return ReportsController(ref);
});

class _SoftLoading extends StatelessWidget {
  const _SoftLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child:
                  CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 12),
            Text('Mengambil laporan…',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

/// Satu tile laporan di feed.
class _ReportTile extends StatelessWidget {
  final ReportEntry entry;
  final bool mine;
  final VoidCallback? onDelete;
  const _ReportTile({required this.entry, this.mine = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isBanjir = entry.isBanjir;
    final color =
        isBanjir ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24);
    final text = isBanjir ? 'BANJIR' : 'JALAN DITUTUP';
    final icon =
        isBanjir ? Icons.water_outlined : Icons.construction_outlined;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(text,
                        style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.kota} · ${_relative(entry.createdAt)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(entry.deskripsi,
                    style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13.5,
                        height: 1.4)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: Colors.white.withValues(alpha: 0.45)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        entry.penulis + (mine ? ' • laporan kamu' : ''),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444), size: 19),
              onPressed: onDelete,
              tooltip: 'Hapus laporan ini',
            ),
        ],
      ),
    );
  }
}

String _relative(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  return '${d.inDays} hari lalu';
}

/// Sheet form laporan: jenis (banjir / tutup jalan), kota auto dari
/// lokasi GPS/beranda yang aktif, deskripsi bebas.
class _ReportFormSheet extends ConsumerStatefulWidget {
  const _ReportFormSheet();

  @override
  ConsumerState<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends ConsumerState<_ReportFormSheet> {
  String _jenis = ReportEntry.jenisBanjir;
  late final TextEditingController _kota = TextEditingController();
  final _deskripsi = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _prefillKota();
  }

  Future<void> _prefillKota() async {
    // Kota default dari lokasi aktif (pilihan manual/GPS/fallback).
    try {
      final loc = await ref.read(locationProvider.future);
      if (!mounted) return;
      setState(() {
        if (_kota.text.trim().isEmpty) _kota.text = loc.name;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _kota.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    double? lat;
    double? lon;
    try {
      final loc = await ref.read(locationProvider.future);
      lat = loc.lat;
      lon = loc.lon;
    } catch (_) {}
    final controller = ref.read(reportsControllerProvider);
    final res = await controller.submit(
      jenis: _jenis,
      kota: _kota.text,
      deskripsi: _deskripsi.text,
      lat: lat,
      lon: lon,
    );
    if (!mounted) return;
    if (res.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFF134E2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _busy = false;
      _message = res.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tulis Laporan',
                  style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                'Laporan bebas boleh berulang — bukan barang susah ditulis ulang.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
              ),
              const SizedBox(height: 14),

              // ── Jenis laporan ──
              Row(
                children: [
                  Expanded(
                    child: _JenisCard(
                      icon: Icons.water_outlined,
                      label: 'Banjir',
                      sub: 'Genangan / sungai meluap',
                      color: const Color(0xFF38BDF8),
                      selected: _jenis == ReportEntry.jenisBanjir,
                      onTap: () => setState(() => _jenis = ReportEntry.jenisBanjir),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _JenisCard(
                      icon: Icons.construction_outlined,
                      label: 'Tutup Jalan',
                      sub: 'Perbaikan / proyek',
                      color: const Color(0xFFFBBF24),
                      selected: _jenis == ReportEntry.jenisTutupJalan,
                      onTap: () => setState(
                          () => _jenis = ReportEntry.jenisTutupJalan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _kota,
                decoration: const InputDecoration(
                  labelText: 'Kota / daerah',
                  prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Isi kota dulu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsi,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Apa yang terjadi?',
                  hintText: 'contoh: Jl. Ahmad Yani tergenang 30 cm selama 2 hari',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Tulis deskripsi dulu' : null,
              ),
              if (_message != null) ...[
                const SizedBox(height: 10),
                Text(_message!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _send,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirim Laporan'),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _JenisCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _JenisCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? color : const Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
