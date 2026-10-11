import 'package:hackathon_salvara/features/reports/domain/report.dart';

/// Contract for report operations.
abstract interface class ReportRepository {
  Future<List<Report>> getReports();

  Future<Report> getReport(String id);

  /// Creates a new submission. Returns submission_id for polling.
  Future<String> createReport({
    required int categoryId,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    String? addressText,
    String? photoPath,
  });

  Future<void> submitFeedback({
    required String reportId,
    required int rating,
    String? comment,
  });
}
