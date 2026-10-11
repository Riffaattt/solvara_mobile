import 'package:hackathon_salvara/features/reports/domain/report.dart';

/// Contract for report operations.
abstract interface class ReportRepository {
  Future<List<Report>> getReports();

  Future<Report> getReport(String id);

  /// Creates a new report. [photoPath] is an optional local file path.
  Future<Report> createReport({
    required String description,
    required ReportCategory category,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? photoPath,
  });

  Future<void> submitFeedback({
    required String reportId,
    required int rating,
    String? comment,
  });
}
