import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/app/router.dart';
import 'package:hackathon_salvara/features/reports/domain/report.dart';
import 'package:hackathon_salvara/features/reports/report_providers.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));

    final report = reportAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      floatingActionButton: report?.status == ReportStatus.resolved
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.feedback(reportId)),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Beri Ulasan'),
            )
          : null,
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorDetail(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportDetailProvider(reportId)),
        ),
        data: (report) => _ReportDetail(report: report),
      ),
    );
  }
}

class _ReportDetail extends StatelessWidget {
  const _ReportDetail({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              _StatusBadge(status: report.status),
              const Spacer(),
              Text(
                _formatDate(report.createdAt),
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title / description
          if (report.title.isNotEmpty) ...[
            Text(report.title, style: textTheme.titleLarge),
            const SizedBox(height: 8),
          ],
          Text(report.description),
          const SizedBox(height: 12),

          // Category
          _LabelRow(label: 'Kategori', value: report.category.label),
          const SizedBox(height: 4),

          // Location
          if (report.locationAddress != null && report.locationAddress!.isNotEmpty)
            _LabelRow(label: 'Lokasi', value: report.locationAddress!),
          if (report.latitude != null && report.longitude != null)
            _LabelRow(
              label: 'Koordinat',
              value: '${report.latitude!.toStringAsFixed(5)}, '
                  '${report.longitude!.toStringAsFixed(5)}',
            ),
          const SizedBox(height: 16),

          // Photos
          if (report.photoUrls.isNotEmpty) ...[
            Text('Foto', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.photoUrls.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report.photoUrls[i],
                    width: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => const SizedBox(
                      width: 240,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Timeline
          if (report.timeline.isNotEmpty) ...[
            Text('Riwayat Status', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            ...report.timeline.map((entry) => _TimelineEntryWidget(entry: entry)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      ReportStatus.resolved => Colors.green.shade700,
      ReportStatus.rejected => cs.error,
      ReportStatus.inProgress => Colors.orange.shade700,
      ReportStatus.underReview => Colors.blue.shade700,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TimelineEntryWidget extends StatelessWidget {
  const _TimelineEntryWidget({required this.entry});

  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(Icons.circle, size: 10),
              Container(width: 2, height: 40, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.status.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (entry.note.isNotEmpty)
                  Text(entry.note, style: const TextStyle(color: Colors.grey)),
                Text(
                  '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  const _ErrorDetail({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Gagal memuat detail laporan.'),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
