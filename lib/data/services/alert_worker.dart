import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/aqi_helper.dart';
import '../../domain/alert_engine.dart';
import '../api/openmeteo_api.dart';
import 'alert_store.dart';
import 'notification_service.dart';

const kAlertTaskName = 'lumair_aqi_alert_check';
const kAlertUniqueName = 'lumair_aqi_alert_periodic';

/// Entry point background. WAJIB top-level + @pragma agar tidak di-tree-shake.
@pragma('vm:entry-point')
void alertCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await AlertChecker().run();
      return true;
    } catch (_) {
      return false; // WorkManager akan mencoba lagi dengan backoff.
    }
  });
}

/// Penjadwalan pengecekan berkala. Android saja (WorkManager).
class AlertScheduler {
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!supported) return;
    await Workmanager().initialize(alertCallbackDispatcher);
  }

  /// Interval minimum Android untuk tugas periodik = 15 menit.
  /// Dipakai 1 jam: cukup untuk peringatan dini, hemat baterai & kuota.
  static Future<void> enable() async {
    if (!supported) return;
    await Workmanager().registerPeriodicTask(
      kAlertUniqueName,
      kAlertTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> disable() async {
    if (!supported) return;
    await Workmanager().cancelByUniqueName(kAlertUniqueName);
  }
}

/// Ringkasan satu putaran pengecekan — supaya UI bisa menjelaskan
/// apa yang sebenarnya terjadi (bukan sekadar "aman").
class AlertRunResult {
  /// Jumlah lokasi yang dipantau.
  final int placeCount;

  /// Lokasi yang gagal diambil datanya (offline/timeout).
  final int fetchFailures;

  /// Peringatan aktif (udara melewati ambang / diprediksi melewati).
  final List<AqiAlert> alerts;

  /// Notifikasi yang berhasil ditampilkan.
  final int sent;

  /// Notifikasi yang gagal ditampilkan (mis. izin ditolak).
  final int showFailures;

  const AlertRunResult({
    this.placeCount = 0,
    this.fetchFailures = 0,
    this.alerts = const [],
    this.sent = 0,
    this.showFailures = 0,
  });

  bool get noPlaces => placeCount == 0;
  bool get allFetchesFailed => placeCount > 0 && fetchFailures == placeCount;
}

/// Satu putaran pengecekan: ambil data tiap lokasi → evaluasi → notifikasi.
/// Dipakai oleh background worker dan tombol "Cek sekarang" di UI.
class AlertChecker {
  final OpenMeteoApi _api;
  final AlertStore _store;
  final NotificationService _notifier;

  AlertChecker({OpenMeteoApi? api, AlertStore? store, NotificationService? notifier})
      : _api = api ?? OpenMeteoApi(),
        _store = store ?? AlertStore(),
        _notifier = notifier ?? NotificationService.instance;

  /// [force] = abaikan cooldown, jam tenang, dan saklar utama (untuk tombol uji).
  Future<AlertRunResult> run({bool force = false, DateTime? now}) async {
    final t = now ?? DateTime.now();
    final settings = await _store.loadSettings();
    if (!settings.enabled && !force) return const AlertRunResult();

    final places = await _store.loadPlaces(includeFavorites: settings.includeFavorites);
    if (places.isEmpty) return const AlertRunResult();

    final history = await _store.loadHistory();
    final active = <AqiAlert>[];
    var sent = 0;
    var fetchFailures = 0;
    var showFailures = 0;

    for (final place in places) {
      AqiAlert? alert;
      try {
        final reading = await _api.getCurrent(
          lat: place.lat,
          lon: place.lon,
          placeName: place.name,
        );
        final forecast = await _api.getHourly24(lat: place.lat, lon: place.lon);
        alert = AlertEngine.evaluate(
          placeKey: place.key,
          placeName: place.name,
          currentAqi: reading.usAqi,
          forecast: forecast,
          settings: settings,
          now: t,
        );
      } catch (_) {
        // Satu lokasi gagal (offline/timeout) tidak boleh menghentikan yang lain.
        fetchFailures++;
        continue;
      }

      if (alert == null) {
        // Udara sudah aman → episode berikutnya boleh memicu notifikasi lagi.
        history.remove(place.key);
        continue;
      }
      active.add(alert);

      if (!force) {
        if (AlertEngine.blockedByQuietHours(alert: alert, settings: settings, now: t)) {
          continue; // tidak dicatat → akan dikirim setelah jam tenang selesai
        }
        if (!AlertEngine.shouldNotify(
            alert: alert, previous: history[place.key], now: t)) {
          continue;
        }
      }

      try {
        await _notifier.show(
          placeKey: place.key,
          title: alert.title,
          body: alert.body,
          color: AqiHelper.color(alert.aqi),
        );
        history[place.key] = AlertHistoryEntry(
          severity: alert.severity,
          kind: alert.kind,
          notifiedAt: t,
        );
        sent++;
      } catch (_) {
        showFailures++;
      }
    }

    await _store.saveHistory(history);
    return AlertRunResult(
      placeCount: places.length,
      fetchFailures: fetchFailures,
      alerts: active,
      sent: sent,
      showFailures: showFailures,
    );
  }
}