import 'package:dio/dio.dart';
import 'package:hackathon_salvara/core/network/dio_client.dart';
import 'package:hackathon_salvara/features/reports/domain/report.dart';
import 'package:hackathon_salvara/features/reports/domain/report_repository.dart';

class ReportRemoteDataSource implements ReportRepository {
  ReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// Unwraps a response envelope: handles `{"data": [...]}` and bare lists/objects.
  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  @override
  Future<List<Report>> getReports() async {
    try {
      final response = await _dio.get<dynamic>('/api/reports');
      final raw = _unwrap(response.data);
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(Report.fromJson).toList();
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<Report> getReport(String id) async {
    try {
      final response = await _dio.get<dynamic>('/api/reports/$id');
      final raw = _unwrap(response.data);
      return Report.fromJson(raw as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<Report> createReport({
    required String description,
    required ReportCategory category,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'description': description,
        'category': category.apiValue,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        // ignore: use_null_aware_elements
        if (locationAddress != null) 'location_address': locationAddress,
        'photo': photoPath != null ? await MultipartFile.fromFile(photoPath) : null,
      });

      final response = await _dio.post<dynamic>(
        '/api/reports',
        data: formData,
      );
      final raw = _unwrap(response.data);
      return Report.fromJson(raw as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<void> submitFeedback({
    required String reportId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post<void>(
        '/api/reports/$reportId/feedback',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }
}
