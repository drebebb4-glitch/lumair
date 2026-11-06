import '../core/aqi_helper.dart';
import 'models/air_quality.dart';
import 'models/alert_settings.dart';

enum AlertKind { current, forecast }

/// Satu peringatan untuk satu lokasi.
class AqiAlert {
  final String placeKey;
  final String placeName;
  final AlertKind kind;

  /// AQI saat ini (kind=current) atau AQI puncak prakiraan (kind=forecast).
  final int aqi;
  final int severity;

  /// Hanya untuk kind=forecast: jam pertama ambang terlewati & jam puncak.
  final DateTime? firstTime;
  final DateTime? peakTime;

  const AqiAlert({
    required this.placeKey,
    required this.placeName,
    required this.kind,
    required this.aqi,
    required this.severity,
    this.firstTime,
    this.peakTime,
  });

  String get category => AqiHelper.category(aqi);

  String get title => kind == AlertKind.current
      ? 'Udara $category di $placeName'
      : 'Peringatan dini: udara di $placeName akan memburuk';

  String get body {
    if (kind == AlertKind.current) {
      return 'AQI $aqi ($category). ${AqiHelper.advice(aqi)}';
    }
    final first = _hhmm(firstTime!);
    final peak = _hhmm(peakTime ?? firstTime!);
    final when = first == peak ? 'sekitar pukul $first' : 'mulai pukul $first, puncak $peak';
    return 'AQI diprediksi mencapai $aqi ($category) $when. '
        '${AqiHelper.advice(aqi)}';
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Catatan peringatan terakhir yang sudah dikirim per lokasi (anti-spam).
class AlertHistoryEntry {
  final int severity;
  final AlertKind kind;
  final DateTime notifiedAt;
  const AlertHistoryEntry({
    required this.severity,
    required this.kind,
    required this.notifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'kind': kind.name,
        'notifiedAt': notifiedAt.toIso8601String(),
      };

  static AlertHistoryEntry? fromJson(Object? raw) {
    try {
      final m = raw as Map<String, dynamic>;
      return AlertHistoryEntry(
        severity: (m['severity'] as num).toInt(),
        kind: AlertKind.values.firstWhere((k) => k.name == m['kind']),
        notifiedAt: DateTime.parse(m['notifiedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Logika murni (tanpa I/O) — mudah di-unit-test.
class AlertEngine {
  /// Jeda minimum sebelum peringatan yang sama diulang untuk lokasi yang sama.
  static const cooldown = Duration(hours: 6);

  /// Kembalikan peringatan bila AQI sekarang / prakiraan melewati ambang.
  /// Null = udara aman (dan history lokasi ini sebaiknya dibersihkan).
  static AqiAlert? evaluate({
    required String placeKey,
    required String placeName,
    required int currentAqi,
    required List<ForecastPoint> forecast,
    required AlertSettings settings,
    required DateTime now,
  }) {
    final min = settings.minSeverity;

    // 1) Sudah melewati ambang sekarang.
    final curSev = AqiHelper.severity(currentAqi);
    if (curSev >= min) {
      return AqiAlert(
        placeKey: placeKey,
        placeName: placeName,
        kind: AlertKind.current,
        aqi: currentAqi,
        severity: curSev,
      );
    }

    // 2) Peringatan dini dari prakiraan beberapa jam ke depan.
    if (!settings.earlyWarning) return null;
    final horizon = now.add(Duration(hours: settings.leadHours));
    final over = forecast
        .where((p) =>
            p.time.isAfter(now.subtract(const Duration(minutes: 30))) &&
            !p.time.isAfter(horizon) &&
            AqiHelper.severity(p.aqi) >= min)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (over.isEmpty) return null;

    final peak = over.reduce((a, b) => b.aqi > a.aqi ? b : a);
    return AqiAlert(
      placeKey: placeKey,
      placeName: placeName,
      kind: AlertKind.forecast,
      aqi: peak.aqi,
      severity: AqiHelper.severity(peak.aqi),
      firstTime: over.first.time,
      peakTime: peak.time,
    );
  }

  /// Apakah peringatan ini perlu dikirim, mengingat history sebelumnya?
  /// Kirim bila: belum pernah, level naik, forecast berubah jadi kenyataan,
  /// atau cooldown sudah lewat.
  static bool shouldNotify({
    required AqiAlert alert,
    required AlertHistoryEntry? previous,
    required DateTime now,
  }) {
    if (previous == null) return true;
    if (alert.severity > previous.severity) return true;
    if (previous.kind == AlertKind.forecast && alert.kind == AlertKind.current) {
      return true;
    }
    return now.difference(previous.notifiedAt) >= cooldown;
  }

  /// Jam tenang menahan notifikasi, kecuali darurat.
  static bool blockedByQuietHours({
    required AqiAlert alert,
    required AlertSettings settings,
    required DateTime now,
  }) {
    return settings.isQuietAt(now) &&
        alert.severity < AlertSettings.emergencySeverity;
  }
}
