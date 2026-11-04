import 'package:flutter_test/flutter_test.dart';
import 'package:lumair/domain/report_provider.dart';

void main() {
  group('ReportEntry.fromJson', () {
    test('keeps reports created before category and location fields', () {
      final report = ReportEntry.fromJson({
        'id': 'report-1',
        'user_id': 'user-1',
        'jenis': ReportCategory.banjir,
        'kota': 'Jakarta',
        'deskripsi': 'Genangan di jalan',
        'created_at': '2026-11-04T10:00:00Z',
      });

      expect(report.kategori, [ReportCategory.banjir]);
      expect(report.lokasi, isEmpty);
      expect(report.hasCoordinates, isFalse);
    });

    test('parses multiple categories and map coordinates', () {
      final report = ReportEntry.fromJson({
        'id': 'report-2',
        'user_id': 'user-2',
        'jenis': ReportCategory.macet,
        'kategori': [ReportCategory.macet, ReportCategory.listrikPadam],
        'kota': 'Bandung',
        'lokasi': 'Jalan Asia Afrika',
        'deskripsi': 'Macet karena listrik padam',
        'lat': -6.9215,
        'lon': 107.6070,
        'created_at': '2026-11-04T10:00:00Z',
      });

      expect(report.kategori, [
        ReportCategory.macet,
        ReportCategory.listrikPadam,
      ]);
      expect(report.lokasi, 'Jalan Asia Afrika');
      expect(report.hasCoordinates, isTrue);
      expect(report.lat, -6.9215);
      expect(report.lon, 107.6070);
    });
  });
}
