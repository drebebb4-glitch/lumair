# LUMAIR — Clarity in Every Breath

App kualitas udara lokal (SDG 11.6), Flutter, API Open-Meteo gratis tanpa key.

## Status mesin ini
Flutter SDK **belum terinstall** di mesin ini (cek `flutter --version` gagal).
Untuk lanjut:
1. Install Flutter stable + Android Studio / Android SDK
2. `cd lumair && flutter pub get`
3. `flutter run` (HP fisik via USB debugging paling gampang untuk GPS)
4. `flutter build apk --debug` untuk prototype

## Struktur (sesuai PRD)
- `lib/core/` theme + aqi_helper + constants
- `lib/data/api/openmeteo_api.dart`
- `lib/data/services/location_service.dart, cache_store.dart`
- `lib/domain/models/air_quality.dart`
- `lib/presentation/screens/home_screen.dart` (+ detail/map/forecast/favorit/education menyusul)

## File tugas
- `../keterangan.md` — data tim
- `../PRD-LUMAIR.md` — PRD penuh
