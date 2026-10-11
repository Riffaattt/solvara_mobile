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
    final primaryColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: report?.status.isResolved == true
          ? FloatingActionButton.extended(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => context.push(AppRoutes.feedback(reportId)),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text(
                'Beri Ulasan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: reportAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
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
    final primaryColor = Colors.blue.shade700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge & Date
                Row(
                  children: [
                    _StatusBadge(status: report.status),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(report.createdAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title / description
                if (report.title.isNotEmpty) ...[
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  report.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // Category & Location
                _LabelRow(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  value: report.categoryName,
                  primaryColor: primaryColor,
                ),
                if (report.addressText != null && report.addressText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _LabelRow(
                    icon: Icons.place_outlined,
                    label: 'Lokasi',
                    value: report.addressText!,
                    primaryColor: primaryColor,
                  ),
                ],
                if (report.latitude != null && report.longitude != null) ...[
                  const SizedBox(height: 12),
                  _LabelRow(
                    icon: Icons.map_outlined,
                    label: 'Koordinat',
                    value: '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                    primaryColor: primaryColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Attachments (photos)
          if (report.attachments.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Foto Bukti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.attachments.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      report.attachments[i].url,
                      width: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => SizedBox(
                        width: 240,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Timeline
          if (report.timeline.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.timeline_outlined, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Status Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: report.timeline
                    .asMap()
                    .entries
                    .map((entry) => _TimelineEntryWidget(
                          entry: entry.value,
                          isLast: entry.key == report.timeline.length - 1,
                          primaryColor: primaryColor,
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
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
      ReportStatus.verified => Colors.green.shade700,
      ReportStatus.rejected => cs.error,
      ReportStatus.inProgress => Colors.orange.shade700,
      ReportStatus.accepted => Colors.blue.shade700,
      _ => Colors.grey.shade600,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        border: Border.all(color: color.withAlpha(77)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _TimelineEntryWidget extends StatelessWidget {
  const _TimelineEntryWidget({
    required this.entry,
    required this.isLast,
    required this.primaryColor,
  });

  final TimelineEntry entry;
  final bool isLast;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 45,
                color: Colors.blue.shade100,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.status.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  const _ErrorDetail({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat detail laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 45,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}