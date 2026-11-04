import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumair/domain/report_provider.dart';
import 'package:lumair/presentation/screens/report_detail_screen.dart';

void main() {
  testWidgets('comments expand and show the offline configuration state',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final report = ReportEntry(
      id: 'report-widget-test',
      userId: 'user-test',
      penulis: 'Pengguna',
      jenis: ReportCategory.banjir,
      kategori: const [ReportCategory.banjir],
      kota: 'Jakarta',
      lokasi: 'Jalan contoh',
      deskripsi: 'Ada genangan.',
      lat: -6.2,
      lon: 106.8,
      createdAt: DateTime(2026, 11, 4),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReportDetailScreen(entry: report, onOpenMap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Rani'), findsNothing);
    await tester.tap(find.byTooltip('Lihat komentar'));
    await tester.pumpAndSettle();
    expect(find.text('Rani'), findsOneWidget);
    expect(
      find.text('Komentar online belum dikonfigurasi untuk aplikasi ini.'),
      findsOneWidget,
    );
  });
}
