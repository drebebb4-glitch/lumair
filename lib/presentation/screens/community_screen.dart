import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/auth_provider.dart';
import '../../domain/providers.dart';
import '../../domain/report_provider.dart';
import '../widgets/glass.dart';
import 'auth_screen.dart';
import 'map_screen.dart';
import 'report_detail_screen.dart';
import '../widgets/report_location_picker.dart';
import '../../core/app_theme.dart';

/// Tab Komunitas LUMAIR — laporan kondisi dan gangguan lokal.
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
        subtitle: 'Bagikan kondisi sekitar dan pantau laporan warga',
        child: _NotConfiguredView(),
      );
    }
    final user = ref.watch(authUserProvider);
    if (user == null) {
      return _ScreenFrame(
        title: 'Laporan Komunitas',
        subtitle: 'Bagikan kondisi sekitar dan pantau laporan warga',
        child: _LoginGateView(onLogin: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }),
      );
    }
    return const _ScreenFrame(
      title: 'Laporan Komunitas',
      subtitle: 'Bagikan kondisi sekitar dan pantau laporan warga',
      child: _ReportBody(),
    );
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
    return const Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_sync_outlined,
                color: AppTheme.warning, size: 42),
            SizedBox(height: 10),
            Text('Belum terhubung ke backend',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'Laporan butuh kredensial Supabase via --dart-define. '
              'Lihat panduan di README repo.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.5),
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
              const Icon(Icons.lock_outline, color: AppTheme.sky, size: 40),
              const SizedBox(height: 10),
              const Text('Laporan butuh akun',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 6),
              const Text(
                'Supaya setiap laporan punya pemilik yang jelas, '
                'masuk (atau daftar) dulu yuk — gratis, cuma email + password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.5),
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
                            color: AppTheme.danger, size: 38),
                        const SizedBox(height: 10),
                        const Text('Gagal memuat laporan',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
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
                                  color: AppTheme.textFaint, size: 40),
                              SizedBox(height: 10),
                              Text('Belum ada laporan',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 6),
                              Text(
                                'Jadi orang pertama! Ketuk tombol + di bawah '
                                'untuk membagikan kondisi dan gangguan di sekitar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppTheme.textMuted,
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final r = list[i];
                      final user = ref.watch(authUserProvider);
                      final mine = user?.id == r.userId;
                      return _ReportTile(
                        entry: r,
                        mine: mine,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(
                              entry: r,
                              onOpenMap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MapScreen(focusReport: r),
                                ),
                              ),
                            ),
                          ),
                        ),
                        onOpenMap: r.hasCoordinates
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MapScreen(focusReport: r),
                                  ),
                                )
                            : null,
                        onDelete: mine
                            ? () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.nightSurface,
                                    title: const Text('Hapus laporan ini?',
                                        style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16)),
                                    content: const Text(
                                        'Laporkan hanya bisa dihapus oleh '
                                        'kamu (pemilik laporannya).',
                                        style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal',
                                            style: TextStyle(
                                                color: AppTheme.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus',
                                            style: TextStyle(
                                                color: AppTheme.danger)),
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
            backgroundColor: AppTheme.accent,
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
      backgroundColor: AppTheme.nightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReportFormSheet(),
    );
  }
}

/// FAB lapor bertumpu di controller provider — biar bisa di-test.
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

/// Satu tile laporan di feed; buka detail dan titik lokasinya.
class _ReportTile extends StatelessWidget {
  final ReportEntry entry;
  final bool mine;
  final VoidCallback onTap;
  final VoidCallback? onOpenMap;
  final VoidCallback? onDelete;
  const _ReportTile({
    required this.entry,
    required this.onTap,
    this.onOpenMap,
    this.mine = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _reportColor(entry.kategori.first);
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                child: Icon(_reportIcon(entry.kategori.first),
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final category in entry.kategori)
                          Text(
                            (ReportCategory.labels[category] ?? category)
                                .toUpperCase(),
                            style: TextStyle(
                              color: _reportColor(category),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.lokasi.isEmpty ? entry.kota : entry.lokasi} · ${_relative(entry.createdAt)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.deskripsi,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    if (onOpenMap != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onOpenMap,
                          icon: const Icon(Icons.map_outlined, size: 15),
                          label: const Text('Lihat lokasi di peta'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.45)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${entry.penulis}${mine ? ' • laporan kamu' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
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
                      color: AppTheme.danger, size: 19),
                  onPressed: onDelete,
                  tooltip: 'Hapus laporan ini',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _reportColor(String category) => switch (category) {
      ReportCategory.banjir => AppTheme.sky,
      ReportCategory.tutupJalan => AppTheme.warning,
      ReportCategory.listrikPadam => const Color(0xFFFACC15),
      ReportCategory.airPadam => const Color(0xFF2DD4BF),
      ReportCategory.macet => const Color(0xFFFB923C),
      ReportCategory.kebakaran => const Color(0xFFFB7185),
      _ => AppTheme.textMuted,
    };

IconData _reportIcon(String category) => switch (category) {
      ReportCategory.banjir => Icons.water_outlined,
      ReportCategory.tutupJalan => Icons.construction_outlined,
      ReportCategory.listrikPadam => Icons.bolt_outlined,
      ReportCategory.airPadam => Icons.water_drop_outlined,
      ReportCategory.macet => Icons.traffic_outlined,
      ReportCategory.kebakaran => Icons.local_fire_department_outlined,
      _ => Icons.report_outlined,
    };

String _relative(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
  if (d.inHours < 24) return '${d.inHours} jam lalu';
  return '${d.inDays} hari lalu';
}

/// Form laporan dengan beberapa kategori dan titik kejadian dari peta.
class _ReportFormSheet extends ConsumerStatefulWidget {
  const _ReportFormSheet();

  @override
  ConsumerState<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends ConsumerState<_ReportFormSheet> {
  final Set<String> _categories = {ReportCategory.banjir};
  late final TextEditingController _kota = TextEditingController();
  final _deskripsi = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  String? _locationLabel;
  LatLng? _initialPoint;
  LatLng? _point;

  @override
  void initState() {
    super.initState();
    _prefillLocation();
  }

  Future<void> _prefillLocation() async {
    try {
      final loc = await ref.read(locationProvider.future);
      if (!mounted) return;
      setState(() {
        if (_kota.text.trim().isEmpty) _kota.text = loc.name;
        _initialPoint ??= LatLng(loc.lat, loc.lon);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Gagal mendapatkan lokasi awal: $error');
    }
  }

  Future<void> _pickLocation() async {
    final initial =
        _point ?? _initialPoint ?? const LatLng(-6.2, 106.816666);
    final selected = await pickReportLocation(
      context,
      initialLocation: initial,
    );
    if (selected == null || !mounted) return;

    var locationLabel =
        '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}';
    String? city;
    try {
      final marks =
          await placemarkFromCoordinates(selected.latitude, selected.longitude);
      if (marks.isNotEmpty) {
        final mark = marks.first;
        final detail = [
          mark.name,
          mark.street,
          mark.subLocality,
          mark.locality,
          mark.subAdministrativeArea,
          mark.administrativeArea,
        ].whereType<String>().map((value) => value.trim()).where((value) {
          return value.isNotEmpty && value != locationLabel;
        }).toSet().toList();
        if (detail.isNotEmpty) locationLabel = detail.join(', ');
        city = mark.locality?.trim().isNotEmpty == true
            ? mark.locality
            : mark.administrativeArea;
      }
    } catch (_) {
      // Koordinat tetap menjadi alamat akurat saat reverse geocoding gagal.
    }
    if (!mounted) return;
    setState(() {
      _point = selected;
      _locationLabel = locationLabel;
      if (city?.trim().isNotEmpty == true) _kota.text = city!.trim();
      _message = null;
    });
  }

  @override
  void dispose() {
    _kota.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categories.isEmpty) {
      setState(() => _message = 'Pilih setidaknya satu kategori.');
      return;
    }
    final point = _point;
    if (point == null || _locationLabel == null) {
      setState(() => _message = 'Pilih titik lokasi laporan melalui peta.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final controller = ref.read(reportsControllerProvider);
    final res = await controller.submit(
      kategori: _categories.toList(),
      kota: _kota.text,
      lokasi: _locationLabel!,
      deskripsi: _deskripsi.text,
      lat: point.latitude,
      lon: point.longitude,
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
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const SizedBox(height: 4),
              Text(
                'Laporan bebas boleh berulang — bukan barang susah ditulis ulang.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(height: 14),

              const Text(
                'Pilih kategori (bisa lebih dari satu)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in ReportCategory.all)
                    FilterChip(
                      avatar: Icon(
                        _reportIcon(category),
                        size: 17,
                        color: _categories.contains(category)
                            ? _reportColor(category)
                            : AppTheme.textMuted,
                      ),
                      label: Text(ReportCategory.labels[category]!),
                      selected: _categories.contains(category),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _categories.add(category);
                        } else {
                          _categories.remove(category);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: Text(_point == null
                    ? 'Pilih titik lokasi di peta'
                    : 'Ubah titik lokasi di peta'),
              ),
              if (_locationLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  _locationLabel!,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
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
                        color: AppTheme.danger, fontSize: 12.5)),
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
