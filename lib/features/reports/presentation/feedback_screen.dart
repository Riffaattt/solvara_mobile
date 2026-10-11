import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackathon_salvara/core/errors/app_exception.dart';
import 'package:hackathon_salvara/features/reports/report_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _errorMessage = 'Pilih rating terlebih dahulu.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(reportRepositoryProvider).submitFeedback(
            reportId: widget.reportId,
            rating: _rating,
            comment: _commentCtrl.text.trim().isNotEmpty
                ? _commentCtrl.text.trim()
                : null,
          );
      setState(() => _submitted = true);
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mengirim ulasan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beri Ulasan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _submitted ? _SuccessView(onDone: () => context.pop()) : _FormView(
            rating: _rating,
            commentCtrl: _commentCtrl,
            submitting: _submitting,
            errorMessage: _errorMessage,
            onRatingChanged: (r) => setState(() => _rating = r),
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.rating,
    required this.commentCtrl,
    required this.submitting,
    required this.errorMessage,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int rating;
  final TextEditingController commentCtrl;
  final bool submitting;
  final String? errorMessage;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bagaimana penanganan laporan Anda?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => IconButton(
              icon: Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 36,
              ),
              onPressed: () => onRatingChanged(i + 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(
            labelText: 'Komentar (opsional)',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: submitting ? null : onSubmit,
          child: submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kirim Ulasan'),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Ulasan berhasil dikirim!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Terima kasih atas masukan Anda.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onDone, child: const Text('Kembali')),
      ],
    );
  }
}
