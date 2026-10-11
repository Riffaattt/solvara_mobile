import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/app/router.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/features/reports/report_providers.dart';

/// Polls report-submissions/{id} until accepted or terminal, then navigates.
class SubmissionTrackingScreen extends ConsumerStatefulWidget {
  const SubmissionTrackingScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  ConsumerState<SubmissionTrackingScreen> createState() =>
      _SubmissionTrackingScreenState();
}

class _SubmissionTrackingScreenState
    extends ConsumerState<SubmissionTrackingScreen> {
  static const _pollInterval = Duration(seconds: 3);
  static const _maxAttempts = 40; // ~2 menit

  Timer? _timer;
  int _attempts = 0;
  String _status = 'received';
  String? _errorMessage;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    _timer?.cancel();
    if (_done) return;

    try {
      final result = await ref
          .read(reportDataSourceProvider)
          .getSubmissionStatus(widget.submissionId);

      final status = result['status'] as String;
      final reportId = result['report_id'] as int?;

      if (!mounted) return;
      setState(() => _status = status);

      // Terminal: accepted
      if (status == 'accepted' && reportId != null) {
        setState(() => _done = true);
        ref.invalidate(reportsProvider);
        if (mounted) context.go(AppRoutes.reportDetail(reportId.toString()));
        return;
      }

      // Terminal: error states
      if (status == 'rejected' ||
          status == 'expired' ||
          status == 'processing_failed') {
        setState(() {
          _done = true;
          _errorMessage = _terminalMessage(status);
        });
        return;
      }

      // Continue polling
      _attempts++;
      if (_attempts >= _maxAttempts) {
        setState(() {
          _done = true;
          _errorMessage =
              'Proses memakan waktu lebih lama dari biasanya. Cek kembali Laporan Saya nanti.';
        });
        return;
      }

      _timer = Timer(_pollInterval, _poll);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      // Retry after delay on network error
      _timer = Timer(const Duration(seconds: 5), _poll);
    } catch (_) {
      if (!mounted) return;
      _timer = Timer(const Duration(seconds: 5), _poll);
    }
  }

  String _terminalMessage(String status) => switch (status) {
        'rejected' => 'Laporan tidak dapat diterima. Periksa foto dan deskripsi, lalu coba lagi.',
        'expired' => 'Proses submission kedaluwarsa. Silakan buat laporan baru.',
        _ => 'Terjadi kendala saat memproses laporan. Coba lagi atau hubungi dukungan.',
      };

  String _statusLabel(String status) => switch (status) {
        'received' => 'Submission diterima',
        'queued_for_moderation' => 'Menunggu pemeriksaan foto',
        'moderating' => 'Foto sedang diperiksa',
        'queued_for_duplicate_check' => 'Pemeriksaan awal lolos',
        'checking_duplicates' => 'Memeriksa laporan serupa',
        'duplicate_review' => 'Ditemukan laporan serupa',
        'manual_review' => 'Menunggu pemeriksaan petugas',
        'accepted' => 'Laporan diterima',
        'rejected' => 'Submission tidak diterima',
        'linked_to_existing_report' => 'Dikaitkan dengan laporan yang ada',
        'processing_failed' => 'Pemeriksaan mengalami kendala',
        'expired' => 'Submission kedaluwarsa',
        _ => 'Memproses...',
      };

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Status Laporan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorMessage != null
                ? _ErrorView(
                    message: _errorMessage!,
                    onRetry: _status == 'processing_failed'
                        ? () {
                            setState(() {
                              _errorMessage = null;
                              _done = false;
                              _attempts = 0;
                            });
                            _poll();
                          }
                        : null,
                    onGoHome: () => context.go(AppRoutes.reports),
                  )
                : _ProgressView(
                    status: _status,
                    label: _statusLabel(_status),
                    primaryColor: primaryColor,
                    onRefresh: () {
                      setState(() => _attempts = 0);
                      _poll();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({
    required this.status,
    required this.label,
    required this.primaryColor,
    required this.onRefresh,
  });

  final String status;
  final String label;
  final Color primaryColor;
  final VoidCallback onRefresh;

  bool get _isSlowStatus =>
      status == 'manual_review' || status == 'duplicate_review';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hourglass_top_rounded, size: 48, color: primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _isSlowStatus
              ? 'Proses ini mungkin membutuhkan waktu lebih lama.'
              : 'Laporan sedang diproses secara otomatis...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(color: primaryColor),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Perbarui status'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onGoHome,
    this.onRetry,
  });

  final String message;
  final VoidCallback onGoHome;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline, size: 48, color: Colors.red),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 32),
        if (onRetry != null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onGoHome,
            child: const Text('Ke Laporan Saya'),
          ),
        ),
      ],
    );
  }
}
