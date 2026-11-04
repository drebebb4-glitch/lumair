# LUMAIR — Clarity in Every Breath

App kualitas udara lokal (SDG 11.6), Flutter + API Open-Meteo gratis tanpa key,
kini dengan **akun Supabase** & **laporan komunitas** (banjir / tutup jalan).

## Struktur

- `lib/core/` — theme, `aqi_helper` (US AQI 0–500), constants, daftar 20 kota
- `lib/data/`
  - `api/openmeteo_api.dart`, `api/geocoding_api.dart`, `api/articles_api.dart`
  - `services/location_service.dart` (GPS + fallback Jakarta),
    `services/cache_store.dart` (Hive, TTL 30 menit),
    `services/supabase_service.dart`
- `lib/domain/` — model `air_quality.dart`, `providers.dart` (Riverpod),
  `auth_provider.dart` (sesi login), `report_provider.dart` (laporan)
- `lib/presentation/screens/`
  - `home_screen.dart` — verdict AQI + gauge + banner status offline/GPS
  - `forecast_screen.dart` — grafik 24 jam + ringkasan 4 hari
  - `map_screen.dart` — peta AQI (long-press cek titik mana pun)
  - `favorites_screen.dart` — kota tersimpan (maks 5)
  - `education_screen.dart` — artikel berita, kartu kutipan dengan
    **"BACA SELENGKAPNYA"** yang expand inline
  - `detail_screen.dart`, `onboarding_screen.dart`
  - `auth_screen.dart` — masuk/daftar (email + password, Supabase Auth)
  - `community_screen.dart` — feed + tulis **laporan banjir & tutup jalan**
- `supabase/schema.sql` — tabel `reports` + Row Level Security (idempotent)

## Fitur komunitas (baru)

| Fitur | Detail |
|---|---|
| Akun | Daftar & masuk via email/password (Supabase Auth), tombol avatar di Beranda |
| Laporan | Banjir & tutup jalan: jenis + kota (auto dari GPS) + deskripsi + titik lokasi |
| Bebas jumlah | Satu akun boleh mengirim laporan berulang kali; hanya laporan sendiri yang bisa dihapus |
| Quote expand | Kartu kutipan edukasi membuka isi artikel inline ("BACA SELENGKAPNYA") |
| Layout orientasi | Halaman detail artikel & detail polutan otomatis 2 kolom saat landscape |

## Jalankan sendiri

```sh
flutter pub get

# Tanpa fitur akun & laporan (fitur publik tetap full):
flutter run

# Dengan fitur akun & laporan (kredensial disuntik, tidak di-hardcode):
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<sb_publishable_...>
```

Setup backend sekali saja:

1. Buat project gratis di supabase.com
2. SQL Editor → jalankan isi `supabase/schema.sql` (tabel + RLS + realtime)
3. Authentication → Providers → **Email aktif**; matikan **Confirm email**
   agar daftar langsung masuk (untuk keperluan tugas/demo)

Build APK:

```sh
flutter build apk --debug
```

## CI

`.github/workflows/ci.yml` menjalankan `flutter analyze` + `flutter test`
pada setiap push/PR ke `main` — status bisa dipantau di tab Actions.
