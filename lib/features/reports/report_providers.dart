import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hackathon_salvara/core/providers.dart';
import 'package:hackathon_salvara/features/reports/data/report_remote_data_source.dart';
import 'package:hackathon_salvara/features/reports/domain/report.dart';
import 'package:hackathon_salvara/features/reports/domain/report_repository.dart';

/// Provides the [ReportRepository] implementation.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRemoteDataSource(ref.watch(dioProvider));
});

/// Fetches the current user's report list.
final reportsProvider = FutureProvider<List<Report>>((ref) async {
  return ref.watch(reportRepositoryProvider).getReports();
});

/// Fetches a single report by id.
final reportDetailProvider =
    FutureProvider.family<Report, String>((ref, id) async {
  return ref.watch(reportRepositoryProvider).getReport(id);
});
