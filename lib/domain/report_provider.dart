import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/supabase_service.dart';
import 'auth_provider.dart';

/// Entry laporan komunitas LUMAIR — banjir & tutup jalan.
class ReportEntry {
  static const jenisBanjir = 'banjir';
  static const jenisTutupJalan = 'tutup_jalan';

  final String id;
  final String userId;
  final String penulis;
  final String jenis;
  final String kota;
  final String deskripsi;
  final DateTime createdAt;
  const ReportEntry({
    required this.id,
    required this.userId,
    required this.penulis,
    required this.jenis,
    required this.kota,
    required this.deskripsi,
    required this.createdAt,
  });

  factory ReportEntry.fromJson(Map<String, dynamic> m) => ReportEntry(
        id: '${m['id']}',
        userId: '${m['user_id']}',
        penulis: '${m['penulis'] ?? 'Anonim'}',
        jenis: '${m['jenis'] ?? 'banjir'}',
        kota: '${m['kota'] ?? '-'}',
        deskripsi: '${m['deskripsi'] ?? ''}',
        createdAt:
            DateTime.tryParse('${m['created_at']}')?.toLocal() ??
                DateTime.now(),
      );

  Map<String, dynamic> toInsert() => {
        'jenis': jenis,
        'kota': kota,
        'deskripsi': deskripsi,
      };

  bool get isBanjir => jenis == jenisBanjir;
}

/// Daftar laporan terbaru (50 terakhir).
/// Kosong/null aman: jika Supabase belum terhubung → error null.
final reportsProvider =
    FutureProvider.autoDispose<List<ReportEntry>>((ref) async {
  if (!SupabaseService.isConfigured) return const [];
  final raw = await SupabaseService.client
      .from('reports')
      .select()
      .order('created_at', ascending: false)
      .limit(50);
  return (raw as List)
      .map((e) => ReportEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Hasil operasi tulis laporan — buat pesan toast/sheet di UI.
class ReportOutcome {
  final bool success;
  final String message;
  const ReportOutcome({required this.success, required this.message});
}

/// Controller insert/delete laporan. Butuh user login di ref.
class ReportsController {
  final Ref ref;
  ReportsController(this.ref);

  Future<ReportOutcome> submit({
    required String jenis,
    required String kota,
    required String deskripsi,
    double? lat,
    double? lon,
  }) async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      return const ReportOutcome(
          success: false, message: 'Masuk dulu untuk mengirim laporan.');
    }
    try {
      if (kota.trim().isEmpty || deskripsi.trim().isEmpty) {
        return const ReportOutcome(
            success: false, message: 'Kota & deskripsi wajib diisi.');
      }
      await SupabaseService.client.from('reports').insert({
        ...ReportEntry(
          id: '',
          userId: user.id,
          penulis: user.displayName,
          jenis: jenis,
          kota: kota.trim(),
          deskripsi: deskripsi.trim(),
          createdAt: DateTime.now(),
        ).toInsert(),
        'user_id': user.id,
        'penulis': user.displayName,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      });
      ref.invalidate(reportsProvider);
      return const ReportOutcome(
          success: true, message: 'Laporan terkirim — terima kasih!');
    } catch (_) {
      return const ReportOutcome(
          success: false, message: 'Gagal mengirim — cek koneksi internet.');
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
