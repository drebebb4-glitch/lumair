/// Pengaturan notifikasi peringatan dini kualitas udara.
///
/// Disimpan sebagai JSON di SharedPreferences (lihat AlertStore) sehingga
/// bisa dibaca juga oleh background worker yang berjalan di isolate terpisah.
class AlertSettings {
  /// Master switch.
  final bool enabled;

  /// Ambang peringatan memakai level severity dari `AqiHelper.severity`:
  /// 2 = Sensitif (AQI > 100), 3 = Tidak Sehat (> 150), 4 = Sangat Tidak Sehat (> 200).
  final int minSeverity;

  /// Peringatan dini: beri tahu sebelum udara memburuk, berdasarkan prakiraan.
  final bool earlyWarning;

  /// Seberapa jauh ke depan (jam) prakiraan diperiksa.
  final int leadHours;

  /// Ikut pantau tempat favorit (selain lokasi beranda).
  final bool includeFavorites;

  /// Jam tenang: tidak ada notifikasi, kecuali level "Sangat Tidak Sehat" ke atas.
  final bool quietEnabled;
  final int quietStartHour; // 0..23
  final int quietEndHour; // 0..23

  const AlertSettings({
    this.enabled = false,
    this.minSeverity = 2,
    this.earlyWarning = true,
    this.leadHours = 6,
    this.includeFavorites = true,
    this.quietEnabled = true,
    this.quietStartHour = 22,
    this.quietEndHour = 6,
  });

  static const defaults = AlertSettings();

  /// Level yang boleh menembus jam tenang.
  static const emergencySeverity = 4;

  /// AQI paling kecil untuk sebuah level severity (untuk label di UI).
  static int thresholdFor(int severity) {
    switch (severity) {
      case 2:
        return 101;
      case 3:
        return 151;
      default:
        return 201;
    }
  }

  bool isQuietAt(DateTime t) {
    if (!quietEnabled || quietStartHour == quietEndHour) return false;
    final h = t.hour;
    if (quietStartHour < quietEndHour) {
      return h >= quietStartHour && h < quietEndHour;
    }
    // Melewati tengah malam, mis. 22 -> 6.
    return h >= quietStartHour || h < quietEndHour;
  }

  AlertSettings copyWith({
    bool? enabled,
    int? minSeverity,
    bool? earlyWarning,
    int? leadHours,
    bool? includeFavorites,
    bool? quietEnabled,
    int? quietStartHour,
    int? quietEndHour,
  }) {
    return AlertSettings(
      enabled: enabled ?? this.enabled,
      minSeverity: minSeverity ?? this.minSeverity,
      earlyWarning: earlyWarning ?? this.earlyWarning,
      leadHours: leadHours ?? this.leadHours,
      includeFavorites: includeFavorites ?? this.includeFavorites,
      quietEnabled: quietEnabled ?? this.quietEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'minSeverity': minSeverity,
        'earlyWarning': earlyWarning,
        'leadHours': leadHours,
        'includeFavorites': includeFavorites,
        'quietEnabled': quietEnabled,
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
      };

  factory AlertSettings.fromJson(Map<String, dynamic> m) {
    const d = AlertSettings.defaults;
    int hour(Object? v, int fallback) {
      final n = (v as num?)?.toInt() ?? fallback;
      return n.clamp(0, 23);
    }

    return AlertSettings(
      enabled: m['enabled'] as bool? ?? d.enabled,
      minSeverity: ((m['minSeverity'] as num?)?.toInt() ?? d.minSeverity).clamp(2, 4),
      earlyWarning: m['earlyWarning'] as bool? ?? d.earlyWarning,
      leadHours: ((m['leadHours'] as num?)?.toInt() ?? d.leadHours).clamp(1, 24),
      includeFavorites: m['includeFavorites'] as bool? ?? d.includeFavorites,
      quietEnabled: m['quietEnabled'] as bool? ?? d.quietEnabled,
      quietStartHour: hour(m['quietStartHour'], d.quietStartHour),
      quietEndHour: hour(m['quietEndHour'], d.quietEndHour),
    );
  }
}
