import 'package:flutter_test/flutter_test.dart';
import 'package:lumair/domain/alert_engine.dart';
import 'package:lumair/domain/models/air_quality.dart';
import 'package:lumair/domain/models/alert_settings.dart';

void main() {
  final now = DateTime(2026, 11, 6, 14, 0);
  const settings = AlertSettings(enabled: true, minSeverity: 2, leadHours: 6);

  List<ForecastPoint> fc(Map<int, int> hourToAqi) => [
        for (final e in hourToAqi.entries)
          ForecastPoint(
              time: DateTime(2026, 11, 6, e.key), aqi: e.value, pm25: 10),
      ];

  AqiAlert? eval(int cur, List<ForecastPoint> f, [AlertSettings s = settings]) =>
      AlertEngine.evaluate(
        placeKey: 'k',
        placeName: 'Jakarta',
        currentAqi: cur,
        forecast: f,
        settings: s,
        now: now,
      );

  test('udara aman & prakiraan aman -> tidak ada peringatan', () {
    expect(eval(60, fc({15: 70, 16: 80})), isNull);
  });

  test('AQI sekarang melewati ambang -> peringatan current', () {
    final a = eval(130, const [])!;
    expect(a.kind, AlertKind.current);
    expect(a.severity, 2);
  });

  test('prakiraan melewati ambang dalam jendela -> peringatan dini', () {
    final a = eval(80, fc({15: 90, 17: 120, 18: 160}))!;
    expect(a.kind, AlertKind.forecast);
    expect(a.aqi, 160);
    expect(a.firstTime, DateTime(2026, 11, 6, 17));
    expect(a.peakTime, DateTime(2026, 11, 6, 18));
  });

  test('lonjakan di luar jendela leadHours diabaikan', () {
    expect(eval(80, fc({23: 180})), isNull); // 14:00 + 6 jam = 20:00
  });

  test('earlyWarning dimatikan -> prakiraan diabaikan', () {
    expect(
        eval(80, fc({17: 160}), settings.copyWith(earlyWarning: false)), isNull);
  });

  test('ambang lebih tinggi tidak memicu pada level Sensitif', () {
    expect(eval(130, const [], settings.copyWith(minSeverity: 3)), isNull);
  });

  test('anti-spam: cooldown, eskalasi, dan forecast jadi kenyataan', () {
    final a = eval(130, const [])!; // sev 2, current
    AlertHistoryEntry h(int sev, AlertKind k, Duration ago) =>
        AlertHistoryEntry(severity: sev, kind: k, notifiedAt: now.subtract(ago));

    bool should(AlertHistoryEntry? p) =>
        AlertEngine.shouldNotify(alert: a, previous: p, now: now);

    expect(should(null), isTrue);
    expect(should(h(2, AlertKind.current, const Duration(hours: 1))), isFalse);
    expect(should(h(2, AlertKind.current, const Duration(hours: 7))), isTrue);
    expect(should(h(1, AlertKind.current, const Duration(hours: 1))), isTrue);
    expect(should(h(2, AlertKind.forecast, const Duration(hours: 1))), isTrue);
  });

  test('jam tenang melewati tengah malam & pengecualian darurat', () {
    const s = AlertSettings(quietEnabled: true, quietStartHour: 22, quietEndHour: 6);
    expect(s.isQuietAt(DateTime(2026, 11, 6, 23)), isTrue);
    expect(s.isQuietAt(DateTime(2026, 11, 6, 3)), isTrue);
    expect(s.isQuietAt(DateTime(2026, 11, 6, 12)), isFalse);

    final night = DateTime(2026, 11, 6, 23);
    AqiAlert alert(int aqi) => AqiAlert(
        placeKey: 'k',
        placeName: 'X',
        kind: AlertKind.current,
        aqi: aqi,
        severity: aqi > 200 ? 4 : 2);
    expect(
        AlertEngine.blockedByQuietHours(alert: alert(130), settings: s, now: night),
        isTrue);
    expect(
        AlertEngine.blockedByQuietHours(alert: alert(250), settings: s, now: night),
        isFalse);
  });

  test('AlertSettings JSON round-trip', () {
    const s = AlertSettings(enabled: true, minSeverity: 3, leadHours: 12);
    final r = AlertSettings.fromJson(s.toJson());
    expect(r.enabled, isTrue);
    expect(r.minSeverity, 3);
    expect(r.leadHours, 12);
  });
}
