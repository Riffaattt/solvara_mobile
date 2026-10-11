import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:hackathon_salvara/core/network/dio_client.dart';
import 'package:hackathon_salvara/features/reports/domain/category.dart';
import 'package:hackathon_salvara/features/reports/domain/report.dart';
import 'package:hackathon_salvara/features/reports/domain/report_repository.dart';

class ReportRemoteDataSource implements ReportRepository {
  ReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// Unwraps `{"data": [...]}` or `{"data": {...}}` envelope.
  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// Fetches active categories from `GET /categories`.
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get<dynamic>('categories');
      final raw = _unwrap(response.data);
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<List<Report>> getReports() async {
    try {
      final response = await _dio.get<dynamic>('reports');
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
      final response = await _dio.get<dynamic>('reports/$id');
      final raw = _unwrap(response.data);
      return Report.fromJson(raw as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  @override
  Future<String> createReport({
    required int categoryId,
    required String title,
    required String description,
    double? latitude,
    double? longitude,
    String? addressText,
    String? photoPath,
  }) async {
    try {
      // occurred_at is required by the API — use today's date.
      final today = DateTime.now().toUtc().toIso8601String().split('T').first;

      // Build fields map without the file.
      final fields = <String, dynamic>{
        'selected_category_id': categoryId.toString(),
        'title': title,
        'description': description,
        'occurred_at': today,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (addressText != null) 'address_text': addressText,
      };

      // Add file separately as attachments[] so Laravel receives it as an array.
      // contentType must be set explicitly — backend validates mimes:jpeg,jpg,png,webp.
      final files = <MapEntry<String, MultipartFile>>[];
      if (photoPath != null) {
        final ext = photoPath.split('.').last.toLowerCase();
        final mime = switch (ext) {
          'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
          'png'           => MediaType('image', 'png'),
          'webp'          => MediaType('image', 'webp'),
          _               => MediaType('image', 'jpeg'),
        };
        files.add(MapEntry(
          'attachments[]',
          await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split('/').last,
            contentType: mime,
          ),
        ));
      }

      final formData = FormData()
        ..fields.addAll(
          fields.entries.map((e) => MapEntry(e.key, e.value.toString())),
        )
        ..files.addAll(files);

      final response = await _dio.post<dynamic>('report-submissions', data: formData);
      final raw = _unwrap(response.data);
      // Returns 202 + submission_id. Caller must poll getSubmissionStatus().
      return raw['submission_id']?.toString() ?? '';
    } on DioException catch (e) {
      throw dioToAppException(e);
    }
  }

  /// Polls `GET /api/v1/report-submissions/{id}`.
  /// Returns map with keys: status (String), report_id (int?).
  Future<Map<String, dynamic>> getSubmissionStatus(String submissionId) async {
    try {
      final response = await _dio.get<dynamic>('report-submissions/$submissionId');
      final raw = _unwrap(response.data) as Map<String, dynamic>;
      return {
        'status': raw['status']?.toString() ?? 'received',
        'report_id': raw['report_id'] as int?,
      };
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
        'reports/$reportId/feedback',
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
