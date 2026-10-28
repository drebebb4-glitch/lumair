import 'package:flutter/material.dart';

/// Kontrak global AQI — semua modul WAJIB pakai ini.
/// Standar: US AQI 0-500.
class AqiHelper {
  static String category(int aqi) {
    if (aqi <= 50) return 'Baik';
    if (aqi <= 100) return 'Sedang';
    if (aqi <= 150) return 'Sensitif';
    if (aqi <= 200) return 'Tidak Sehat';
    if (aqi <= 300) return 'Sangat Tidak Sehat';
    return 'Berbahaya';
  }

  static Color color(int aqi) {
    if (aqi <= 50) return const Color(0xFF22C55E);
    if (aqi <= 100) return const Color(0xFFEAB308);
    if (aqi <= 150) return const Color(0xFFF97316);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFFA855F7);
    return const Color(0xFF7F1D1D);
  }

  static String advice(int aqi, {bool sensitive = false}) {
    if (aqi <= 50) return 'Udara bersih. Aman beraktivitas di luar.';
    if (aqi <= 100) {
      return sensitive
          ? 'Udara sedang. Kamu sensitif: kurangi lama outdoor.'
          : 'Udara sedang. Aman, tapi sensitif tetap waspada.';
    }
    if (aqi <= 150) {
      return 'AQI $aqi: pakai masker bila lama di luar. Anak & penderita asma batasi outdoor.';
    }
    return 'AQI $aqi: wajib masker, hindari outdoor lama. Anak/asma indoor, olahraga indoor saja.';
  }

  static String dominantLabel(String key) {
    switch (key) {
      case 'pm2_5':
        return 'PM2.5';
      case 'pm10':
        return 'PM10';
      case 'o3':
        return 'Ozon (O3)';
      case 'no2':
        return 'NO2';
      case 'so2':
        return 'SO2';
      case 'co':
        return 'CO';
      default:
        return key;
    }
  }
}
