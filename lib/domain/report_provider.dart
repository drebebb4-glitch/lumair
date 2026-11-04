import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/supabase_service.dart';
import 'auth_provider.dart';

class ReportCategory {
  static const banjir = 'banjir';
  static const tutupJalan = 'tutup_jalan';
  static const listrikPadam = 'listrik_padam';
  static const airPadam = 'air_padam';
  static const macet = 'macet';
  static const kebakaran = 'kebakaran';

  static const all = [
    banjir,
    tutupJalan,
    listrikPadam,
    airPadam,
    macet,
    kebakaran,
  ];

  static const labels = {
    banjir: 'Banjir',
    tutupJalan: 'Jalan ditutup',
    listrikPadam: 'Listrik padam',
    airPadam: 'Air padam',
    macet: 'Macet',
    kebakaran: 'Kebakaran',
  };
}

/// Laporan komunitas; [jenis] menyimpan kategori utama untuk data lama.
class ReportEntry {
  static const jenisBanjir = ReportCategory.banjir;
  static const jenisTutupJalan = ReportCategory.tutupJalan;

  final String id;
  final String userId;
  final String penulis;
  final String jenis;
  final List<String> kategori;
  final String kota;
  final String lokasi;
  final String deskripsi;
  final double? lat;
  final double? lon;
  final DateTime createdAt;

  const ReportEntry({
    required this.id,
    required this.userId,
    required this.penulis,
    required this.jenis,
    required this.kategori,
    required this.kota,
    required this.lokasi,
    required this.deskripsi,
    required this.lat,
    required this.lon,
    required this.createdAt,
  });

  factory ReportEntry.fromJson(Map<String, dynamic> json) {
    final jenis = '${json['jenis'] ?? ReportCategory.banjir}';
    final rawCategories = json['kategori'];
    final categories = rawCategories is List
        ? rawCategories.whereType<String>().toSet().toList()
        : <String>[];
    if (categories.isEmpty) categories.add(jenis);
    return ReportEntry(
      id: '${json['id']}',
      userId: '${json['user_id']}',
      penulis: '${json['penulis'] ?? 'Anonim'}',
      jenis: jenis,
      kategori: categories,
      kota: '${json['kota'] ?? '-'}',
      lokasi: '${json['lokasi'] ?? ''}',
      deskripsi: '${json['deskripsi'] ?? ''}',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  bool get isBanjir => kategori.contains(ReportCategory.banjir);
  bool get hasCoordinates => lat != null && lon != null;
}

class ReportComment {
  final String id;
  final String reportId;
  final String userId;
  final String penulis;
  final String isi;
  final DateTime createdAt;

  const ReportComment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.penulis,
    required this.isi,
    required this.createdAt,
  });

  factory ReportComment.fromJson(Map<String, dynamic> json) => ReportComment(
        id: '${json['id']}',
        reportId: '${json['report_id']}',
        userId: '${json['user_id']}',
        penulis: '${json['penulis'] ?? 'Anonim'}',
        isi: '${json['isi'] ?? ''}',
        createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
            DateTime.now(),
      );
}

/// Daftar laporan terbaru (50 terakhir).
final reportsProvider =
    FutureProvider.autoDispose<List<ReportEntry>>((ref) async {
  if (!SupabaseService.isConfigured) return const [];
  final raw = await SupabaseService.client
      .from('reports')
      .select()
      .order('created_at', ascending: false)
      .limit(100);
  return (raw as List)
      .map((item) => ReportEntry.fromJson(item as Map<String, dynamic>))
      .toList();
});

final reportCommentsProvider = StreamProvider.autoDispose
    .family<List<ReportComment>, ReportEntry>((ref, entry) async* {
  final json = await rootBundle.loadString('assets/dummy/report_comments.json');
  final samples = jsonDecode(json) as Map<String, dynamic>;
  final localComments = localCommentsForReport(entry, samples);
  if (!SupabaseService.isConfigured) {
    yield localComments;
    return;
  }

  final remoteStream = SupabaseService.client
      .from('report_comments')
      .stream(primaryKey: ['id'])
      .eq('report_id', entry.id)
      .order('created_at');
  await for (final rawComments in remoteStream) {
    final remoteComments = rawComments.map(ReportComment.fromJson);
    yield [...localComments, ...remoteComments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
});

List<ReportComment> localCommentsForReport(
  ReportEntry entry,
  Map<String, dynamic> samples,
) {
  final comments = <ReportComment>[];
  for (final category in entry.kategori) {
    final categorySamples = samples[category];
    if (categorySamples is! List) continue;
    for (final sample in categorySamples) {
      if (sample is! Map) continue;
      final item = Map<String, dynamic>.from(sample);
      comments.add(
        ReportComment.fromJson({
          ...item,
          'id': '${entry.id}-${item['id']}',
          'report_id': entry.id,
          'user_id': 'local-demo',
        }),
      );
    }
  }
  comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return comments;
}

class ReportCommentsController {
  final Ref ref;
  ReportCommentsController(this.ref);

  Future<ReportOutcome> submit({
    required ReportEntry entry,
    required String isi,
  }) async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      return const ReportOutcome(
        success: false,
        message: 'Masuk dulu untuk memberi komentar.',
      );
    }
    final text = isi.trim();
    if (text.isEmpty) {
      return const ReportOutcome(
        success: false,
        message: 'Komentar tidak boleh kosong.',
      );
    }
    if (!SupabaseService.isConfigured) {
      return const ReportOutcome(
        success: false,
        message: 'Supabase belum dikonfigurasi untuk aplikasi ini.',
      );
    }

    try {
      await SupabaseService.client.from('report_comments').insert({
        'report_id': entry.id,
        'user_id': user.id,
        'penulis': user.displayName,
        'isi': text,
      });
      ref.invalidate(reportCommentsProvider(entry));
      return const ReportOutcome(
        success: true,
        message: 'Komentar terkirim.',
      );
    } catch (error) {
      final details = '$error';
      if (details.contains('PGRST205') ||
          details.contains('42P01') ||
          details.contains('schema cache')) {
        return const ReportOutcome(
          success: false,
          message:
              'Tabel komentar belum tersedia. Jalankan supabase/schema.sql di Supabase SQL Editor.',
        );
      }
      return ReportOutcome(
        success: false,
        message: 'Gagal mengirim komentar: $details',
      );
    }
  }
}

final reportCommentsControllerProvider =
    Provider<ReportCommentsController>((ref) {
  return ReportCommentsController(ref);
});

class ReportOutcome {
  final bool success;
  final String message;

  const ReportOutcome({required this.success, required this.message});
}

class ReportsController {
  final Ref ref;
  ReportsController(this.ref);

  Future<ReportOutcome> submit({
    required List<String> kategori,
    required String kota,
    required String lokasi,
    required String deskripsi,
    required double lat,
    required double lon,
  }) async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      return const ReportOutcome(
        success: false,
        message: 'Masuk dulu untuk mengirim laporan.',
      );
    }
    final validCategories =
        kategori.where(ReportCategory.all.contains).toSet().toList();
    if (validCategories.isEmpty ||
        kota.trim().isEmpty ||
        lokasi.trim().isEmpty ||
        deskripsi.trim().isEmpty) {
      return const ReportOutcome(
        success: false,
        message: 'Pilih kategori, titik peta, dan isi semua keterangan.',
      );
    }
    if (!SupabaseService.isConfigured) {
      return const ReportOutcome(
        success: false,
        message: 'Backend laporan belum terhubung.',
      );
    }
    try {
      await SupabaseService.client.from('reports').insert({
        'jenis': validCategories.first,
        'kategori': validCategories,
        'kota': kota.trim(),
        'lokasi': lokasi.trim(),
        'deskripsi': deskripsi.trim(),
        'user_id': user.id,
        'penulis': user.displayName,
        'lat': lat,
        'lon': lon,
      });
      ref.invalidate(reportsProvider);
      return const ReportOutcome(
        success: true,
        message: 'Laporan terkirim — terima kasih!',
      );
    } catch (_) {
      return const ReportOutcome(
        success: false,
        message: 'Gagal mengirim — periksa koneksi atau skema Supabase.',
      );
    }
  }

  Future<bool> delete(String id) async {
    final user = ref.read(authUserProvider);
    if (user == null || !SupabaseService.isConfigured) return false;
    try {
      await SupabaseService.client
          .from('reports')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      ref.invalidate(reportsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final reportsControllerProvider = Provider<ReportsController>((ref) {
  return ReportsController(ref);
});
