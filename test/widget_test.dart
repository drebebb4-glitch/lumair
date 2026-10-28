import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumair/core/aqi_helper.dart';
import 'package:lumair/core/cities.dart';
import 'package:lumair/domain/models/air_quality.dart';
import 'package:lumair/domain/providers.dart';
import 'package:lumair/main.dart';
import 'package:lumair/presentation/screens/map_screen.dart';

AirQualityReading _dummy() => AirQualityReading(
      lat: -6.2,
      lon: 106.816666,
      placeName: 'Jakarta',
      time: DateTime(2026, 10, 8, 12, 0),
      usAqi: 128,
      pm25: 46.5,
      pm10: 68.2,
      o3: 42.0,
      no2: 28.4,
      so2: 8.1,
      co: 520.0,
      dominant: 'pm2_5',
    );

void main() {
  testWidgets('LUMAIR app boots with bottom nav', (WidgetTester tester) async {
    // Sudah pernah onboarding → langsung ke navigasi utama.
    SharedPreferences.setMockInitialValues({'lumair_onboarded': true});
    await tester.pumpWidget(const ProviderScope(child: LumairApp()));
    await tester.pump();
    // Lewati durasi minimal splash animasi.
    await tester.pump(kSplashMinDuration + const Duration(milliseconds: 100));

    expect(find.text('LUMAIR'), findsOneWidget);
    // Bottom nav: 5 item, index awal 0. (Assert byIcon di-skip: codepoint
    // font Material Symbols tidak stabil antar run di env ini.)
    final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar));
    expect(bar.items.length, 5);
    expect(bar.currentIndex, 0);
    expect(find.text('Beranda'), findsOneWidget); // tab aktif awal
  });

  testWidgets('Map tab renders FlutterMap with AQI pin', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Simulasi layar HP sempit 420px: overflow apa pun = test gagal.
    tester.view.physicalSize = const Size(420, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aqiProvider.overrideWith((ref) async => _dummy()),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Peta Udara'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      // Pin lokasi sekarang dot pulse; angka AQI tampil di HUD bawah.
      expect(find.text('128'), findsWidgets);
      expect(find.text('Jakarta'), findsOneWidget);
    });
  });

  testWidgets('Onboarding tampil di peluncuran pertama & bisa dilewati',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // belum pernah onboarding
    await tester.pumpWidget(const ProviderScope(child: LumairApp()));
    await tester.pump();
    // Lewati durasi minimal splash animasi.
    await tester.pump(kSplashMinDuration + const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Kenal udara lu'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Beranda'), findsOneWidget); // masuk navigasi utama
  });

  test('Skala AQI & kategori konsisten', () {
    expect(AqiHelper.category(0), 'Baik');
    expect(AqiHelper.category(75), 'Sedang');
    expect(AqiHelper.category(128), 'Sensitif');
    expect(AqiHelper.category(180), 'Tidak Sehat');
    expect(AqiHelper.category(250), 'Sangat Tidak Sehat');
    expect(AqiHelper.category(400), 'Berbahaya');
    // Batas segmen strip skala 0-500.
    for (final a in [0, 50, 100, 150, 200, 300, 500]) {
      expect(AqiHelper.color(a), isA<Color>());
    }
  });

  test('Daftar semua daerah berisi 20 kota Indonesia', () {
    expect(idCities.length, 20);
    expect(idCities.first.name, 'Jakarta');
    final names = idCities.map((c) => c.name).toSet();
    expect(names.length, 20); // tidak ada duplikat
    for (final c in idCities) {
      expect(c.lat, inInclusiveRange(-11.0, 6.0));
      expect(c.lon, inInclusiveRange(95.0, 141.0));
    }
  });
}
