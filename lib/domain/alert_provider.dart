import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/alert_store.dart';
import '../data/services/alert_worker.dart';
import '../data/services/location_service.dart';
import '../data/services/notification_service.dart';
import 'models/alert_settings.dart';
import 'providers.dart';

class AlertSettingsNotifier extends StateNotifier<AlertSettings> {
  final AlertStore _store = AlertStore();

  AlertSettingsNotifier() : super(AlertSettings.defaults) {
    _load();
  }

  Future<void> _load() async {
    state = await _store.loadSettings();
    if (state.enabled) await _schedule(true); // pastikan tugas tetap terdaftar
  }

  Future<void> _schedule(bool on) async {
    try {
      on ? await AlertScheduler.enable() : await AlertScheduler.disable();
    } catch (_) {}
  }

  /// Aktif/nonaktifkan fitur. Mengembalikan false bila izin notifikasi ditolak.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      bool ok = true;
      try {
        ok = await NotificationService.instance.requestPermission();
      } catch (_) {}
      if (!ok) return false;
    }
    state = state.copyWith(enabled: value);
    await _store.saveSettings(state);
    await _schedule(value);
    return true;
  }

  Future<void> update(AlertSettings Function(AlertSettings s) change) async {
    state = change(state);
    await _store.saveSettings(state);
  }
}

final alertSettingsProvider =
    StateNotifierProvider<AlertSettingsNotifier, AlertSettings>(
        (ref) => AlertSettingsNotifier());

/// Menyalin lokasi beranda terbaru ke penyimpanan agar background worker
/// tahu di mana harus memantau. Cukup di-`watch` sekali di root navigasi.
final alertLocationSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserLocation>>(
    locationProvider,
    (_, next) => next.whenData((loc) => AlertStore().saveHome(loc)),
    fireImmediately: true,
  );
});
