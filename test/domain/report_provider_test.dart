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

  test('local report comments only include examples for matching categories',
      () {
    final report = ReportEntry.fromJson({
      'id': 'report-1',
      'user_id': 'user-1',
      'jenis': ReportCategory.banjir,
      'kategori': [ReportCategory.banjir, ReportCategory.macet],
      'kota': 'Jakarta',
      'deskripsi': 'Genangan di jalan',
      'created_at': '2026-11-04T10:00:00Z',
    });

    final comments = localCommentsForReport(report, {
      ReportCategory.banjir: [
        {
          'id': 'banjir-1',
          'penulis': 'Rani',
          'isi': 'Hati-hati saat melintas.',
          'created_at': '2026-11-04T08:15:00Z',
        },
      ],
      ReportCategory.listrikPadam: [
        {
          'id': 'listrik-1',
          'penulis': 'Ayu',
          'isi': 'Di sini juga padam.',
          'created_at': '2026-11-04T09:05:00Z',
        },
      ],
    });

    expect(comments, hasLength(1));
    expect(comments.single.reportId, report.id);
    expect(comments.single.penulis, 'Rani');
  });

  test('parses a Supabase report comment', () {
    final comment = ReportComment.fromJson({
      'id': 'comment-1',
      'report_id': 'report-1',
      'user_id': 'user-1',
      'penulis': 'Rani',
      'isi': 'Hati-hati saat melintas.',
      'created_at': '2026-11-04T08:15:00Z',
    });

    expect(comment.id, 'comment-1');
    expect(comment.reportId, 'report-1');
    expect(comment.penulis, 'Rani');
    expect(comment.isi, 'Hati-hati saat melintas.');
  });
}
