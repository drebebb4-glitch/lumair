import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_provider.dart';
import '../../domain/report_provider.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/glass.dart';
import 'auth_screen.dart';
import '../../core/app_theme.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.entry,
    required this.onOpenMap,
  });

  final ReportEntry entry;
  final VoidCallback onOpenMap;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final _commentController = TextEditingController();
  bool _showComments = false;
  bool _sending = false;
  String? _message;
  bool _sendFailed = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      final result = await ref.read(reportCommentsControllerProvider).submit(
            entry: widget.entry,
            isi: _commentController.text,
          );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _message = result.message;
        _sendFailed = !result.success;
      });
      if (result.success) _commentController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _message = 'Komentar gagal disimpan: $error';
        _sendFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final user = ref.watch(authUserProvider);
    final comments = ref.watch(reportCommentsProvider(entry));
    final commentCount = comments.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail laporan')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reportCommentsProvider(entry).future),
        child: ListView(
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
                      color: AppTheme.textPrimary,
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
                        onPressed: widget.onOpenMap,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Komentar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: _showComments
                          ? 'Sembunyikan komentar'
                          : 'Lihat komentar',
                      onPressed: () =>
                          setState(() => _showComments = !_showComments),
                      icon: Icon(
                        _showComments
                            ? Icons.mode_comment
                            : Icons.mode_comment_outlined,
                        color: AppTheme.accent,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: AppTheme.emerald,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$commentCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_showComments) ...[
              const SizedBox(height: 8),
              comments.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => GlassCard(
                  child: Text(
                    _commentLoadError(error),
                    style: const TextStyle(
                      color: Color(0xFFFECACA),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty)
                      const GlassCard(
                        child: Text(
                          'Belum ada komentar.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    else
                      for (final comment in items) ...[
                        _CommentTile(comment: comment),
                        if (comment != items.last) const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 12),
                    if (!SupabaseService.isConfigured)
                      const GlassCard(
                        child: Text(
                          'Komentar online belum dikonfigurasi untuk aplikasi ini.',
                          style: TextStyle(color: Color(0xFFFECACA)),
                        ),
                      )
                    else if (user == null)
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text('Masuk untuk berkomentar'),
                      )
                    else ...[
                      TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Tulis komentar…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _sendFailed
                                  ? AppTheme.dangerSoft
                                  : AppTheme.accent,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _sending ? null : _addComment,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Tambah komentar'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
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
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
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
      labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
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
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                _dateTime(comment.createdAt),
                style: const TextStyle(
                  color: AppTheme.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.isi,
            style: const TextStyle(
              color: AppTheme.textSoft,
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

String _commentLoadError(Object error) {
  final details = '$error';
  if (details.contains('PGRST205') ||
      details.contains('42P01') ||
      details.contains('schema cache')) {
    return 'Tabel komentar belum tersedia. Jalankan supabase/schema.sql di Supabase SQL Editor.';
  }
  return 'Komentar gagal dimuat. Periksa koneksi Supabase, lalu tarik layar untuk mencoba lagi.';
}
