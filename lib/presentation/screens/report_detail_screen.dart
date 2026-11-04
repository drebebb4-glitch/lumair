import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/report_provider.dart';
import '../widgets/glass.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.entry,
    required this.onOpenMap,
  });

  final ReportEntry entry;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = this.entry;
    final comments = ref.watch(reportCommentsProvider(entry));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail laporan')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in entry.kategori)
                      _CategoryChip(category: category),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  entry.deskripsi,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailLine(
                  icon: Icons.location_city_outlined,
                  title: entry.kota,
                  subtitle: entry.lokasi.isEmpty ? null : entry.lokasi,
                ),
                if (entry.hasCoordinates) ...[
                  const SizedBox(height: 10),
                  _DetailLine(
                    icon: Icons.my_location,
                    title:
                        '${entry.lat!.toStringAsFixed(5)}, ${entry.lon!.toStringAsFixed(5)}',
                    subtitle: 'Titik lokasi laporan',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onOpenMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Lihat titik ini di peta'),
                    ),
                  ),
                ],
                const Divider(height: 24),
                _DetailLine(
                  icon: Icons.person_outline,
                  title: entry.penulis,
                  subtitle: _dateTime(entry.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Komentar contoh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Contoh lokal dari assets/dummy/report_comments.json. '
              'Perbarui file tersebut lalu commit ke GitHub untuk mengganti contoh.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          comments.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => GlassCard(
              child: Text(
                'Komentar gagal dimuat: $error',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFECACA),
                  fontSize: 12,
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? const GlassCard(
                    child: Text(
                      'Belum ada komentar contoh untuk kategori laporan ini.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : Column(
                    children: [
                      for (final comment in items) ...[
                        _CommentTile(comment: comment),
                        if (comment != items.last) const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF34D399)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.report_outlined, size: 16),
      label: Text(ReportCategory.labels[category] ?? category),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      backgroundColor: const Color(0xFF12203A),
      labelStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ReportComment comment;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.penulis,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                _dateTime(comment.createdAt),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.isi,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _dateTime(DateTime time) {
  final local = time.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
