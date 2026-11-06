import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/aqi_helper.dart';
import '../../data/services/alert_worker.dart';
import '../../data/services/notification_service.dart';
import '../../domain/alert_provider.dart';
import '../../domain/models/alert_settings.dart';
import '../widgets/glass.dart';

/// Pengaturan notifikasi peringatan dini kualitas udara.
class AlertSettingsScreen extends ConsumerStatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  ConsumerState<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends ConsumerState<AlertSettingsScreen> {
  bool _checking = false;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggle(bool value) async {
    final ok = await ref.read(alertSettingsProvider.notifier).setEnabled(value);
    if (!ok && mounted) {
      _toast('Izin notifikasi ditolak. Aktifkan lewat Pengaturan HP → Aplikasi → LUMAIR.');
    }
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    try {
      // Di web izin browser harus diminta dari aksi pengguna (ketukan tombol ini).
      final granted = await NotificationService.instance.requestPermission();
      final r = await AlertChecker().run(force: true);
      if (!mounted) return;
      if (r.noPlaces) {
        _toast('Belum ada lokasi tersimpan. Tunggu lokasi muncul di Beranda, lalu coba lagi.');
      } else if (r.allFetchesFailed) {
        _toast('Gagal mengambil data udara. Cek koneksi internet.');
      } else if (r.alerts.isEmpty) {
        _toast('Aman: udara di semua lokasi masih di bawah ambang peringatan '
            '(ambang saat ini: AQI ≥ ${AlertSettings.thresholdFor(ref.read(alertSettingsProvider).minSeverity)}).');
      } else if (r.sent > 0) {
        _toast('${r.sent} peringatan dikirim. Cek notifikasi.');
      } else {
        _toast(granted
            ? 'Ada peringatan, tapi notifikasi gagal ditampilkan di perangkat ini.'
            : 'Ada peringatan, tapi izin notifikasi belum diberikan. Izinkan notifikasi lalu coba lagi.');
      }
    } catch (_) {
      if (mounted) _toast('Gagal memeriksa. Coba lagi.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _pickHour({required bool start}) async {
    final s = ref.read(alertSettingsProvider);
    final initial = TimeOfDay(hour: start ? s.quietStartHour : s.quietEndHour, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    ref.read(alertSettingsProvider.notifier).update((s) => start
        ? s.copyWith(quietStartHour: picked.hour)
        : s.copyWith(quietEndHour: picked.hour));
  }

  String _hh(int h) => '${h.toString().padLeft(2, '0')}.00';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(alertSettingsProvider);
    final notifier = ref.read(alertSettingsProvider.notifier);
    final active = s.enabled;

    return Scaffold(
      backgroundColor: AppTheme.night,
      appBar: AppBar(title: const Text('Peringatan Dini')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.emerald,
                  title: const Text('Aktifkan peringatan dini', style: AppTextStyles.sectionTitle),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'LUMAIR memeriksa udara di lokasimu secara berkala dan mengirim '
                      'notifikasi sebelum udara jadi tidak sehat — walau aplikasi sedang ditutup.',
                      style: AppTextStyles.hint,
                    ),
                  ),
                  value: active,
                  onChanged: _toggle,
                ),
                if (!AlertScheduler.supported)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      kIsWeb
                          ? 'Mode web (demo): notifikasi hanya muncul lewat tombol di bawah '
                              'dan saat tab LUMAIR masih terbuka. Pemeriksaan otomatis '
                              'di latar belakang hanya ada di Android.'
                          : 'Pemeriksaan di latar belakang saat ini hanya tersedia di Android.',
                      style: AppTextStyles.caption,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Opacity(
            opacity: active ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !active,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KAPAN DIPERINGATKAN', style: AppTextStyles.sectionLabel),
                        const SizedBox(height: 10),
                        for (final sev in const [2, 3, 4]) _severityTile(s, sev, notifier),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppTheme.emerald,
                          title: const Text('Peringatan dini dari prakiraan',
                              style: AppTextStyles.sectionTitle),
                          subtitle: const Text(
                            'Beri tahu beberapa jam sebelum udara memburuk, bukan setelahnya.',
                            style: AppTextStyles.hint,
                          ),
                          value: s.earlyWarning,
                          onChanged: (v) => notifier.update((x) => x.copyWith(earlyWarning: v)),
                        ),
                        if (s.earlyWarning) ...[
                          const SizedBox(height: 4),
                          const Text('Periksa prakiraan hingga', style: AppTextStyles.hint),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final h in const [3, 6, 12])
                                ChoiceChip(
                                  label: Text('$h jam ke depan'),
                                  selected: s.leadHours == h,
                                  onSelected: (_) =>
                                      notifier.update((x) => x.copyWith(leadHours: h)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppTheme.emerald,
                          title: const Text('Pantau tempat favorit',
                              style: AppTextStyles.sectionTitle),
                          subtitle: const Text(
                            'Termasuk semua tempat di tab Favorit, bukan hanya lokasimu.',
                            style: AppTextStyles.hint,
                          ),
                          value: s.includeFavorites,
                          onChanged: (v) =>
                              notifier.update((x) => x.copyWith(includeFavorites: v)),
                        ),
                        const Divider(height: 24, color: Color(0x1FFFFFFF)),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppTheme.emerald,
                          title: const Text('Jam tenang', style: AppTextStyles.sectionTitle),
                          subtitle: Text(
                            'Tidak ada notifikasi ${_hh(s.quietStartHour)}–${_hh(s.quietEndHour)}, '
                            'kecuali udara Sangat Tidak Sehat atau lebih buruk.',
                            style: AppTextStyles.hint,
                          ),
                          value: s.quietEnabled,
                          onChanged: (v) =>
                              notifier.update((x) => x.copyWith(quietEnabled: v)),
                        ),
                        if (s.quietEnabled)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickHour(start: true),
                                  icon: const Icon(Icons.bedtime_outlined, size: 18),
                                  label: Text('Mulai ${_hh(s.quietStartHour)}'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickHour(start: false),
                                  icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                                  label: Text('Selesai ${_hh(s.quietEndHour)}'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _checking ? null : _checkNow,
                      icon: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: Text(_checking ? 'Memeriksa…' : 'Periksa & uji notifikasi sekarang'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Android mengatur waktu pemeriksaan latar belakang (sekitar tiap 1 jam) '
                    'demi hemat baterai, jadi notifikasi bisa terlambat beberapa menit.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityTile(AlertSettings s, int sev, AlertSettingsNotifier notifier) {
    final aqi = AlertSettings.thresholdFor(sev);
    final color = AqiHelper.color(aqi);
    final selected = s.minSeverity == sev;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => notifier.update((x) => x.copyWith(minSeverity: sev)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mulai ${AqiHelper.category(aqi)}', style: AppTextStyles.body),
                  Text(
                    'AQI ≥ $aqi'
                    '${sev == 2 ? ' • paling waspada' : (sev == 4 ? ' • hanya kondisi buruk' : '')}',
                    style: AppTextStyles.hint,
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.emerald : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}