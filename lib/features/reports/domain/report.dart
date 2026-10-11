import 'package:equatable/equatable.dart';

/// Status values from the API.
enum ReportStatus {
  submitted,
  accepted,
  inProgress,
  resolvedPendingVerification,
  verified,
  reopened,
  rejected,
  unknown;

  static ReportStatus fromString(String? value) {
    return switch (value) {
      'submitted' => submitted,
      'accepted' => accepted,
      'in_progress' => inProgress,
      'resolved_pending_verification' => resolvedPendingVerification,
      'verified' => verified,
      'reopened' => reopened,
      'rejected' => rejected,
      _ => unknown,
    };
  }

  String get label => switch (this) {
        submitted => 'Dikirim',
        accepted => 'Diterima',
        inProgress => 'Diproses',
        resolvedPendingVerification => 'Menunggu Verifikasi',
        verified => 'Terverifikasi',
        reopened => 'Dibuka Kembali',
        rejected => 'Ditolak',
        unknown => 'Tidak diketahui',
      };

  bool get isResolved => this == verified;
}

/// A single entry in the report timeline (status history).
class TimelineEntry extends Equatable {
  const TimelineEntry({
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final ReportStatus status;
  final String note;
  final DateTime createdAt;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    // status_history entries use new_status; fall back to status for compatibility.
    final statusStr = json['new_status']?.toString() ?? json['status']?.toString();
    return TimelineEntry(
      status: ReportStatus.fromString(statusStr),
      note: json['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [status, note, createdAt];
}

/// Attachment from `ReportResource.attachments`.
class ReportAttachment extends Equatable {
  const ReportAttachment({
    required this.id,
    required this.url,
    this.mimeType = 'image/jpeg',
  });

  final int id;
  final String url;
  final String mimeType;

  factory ReportAttachment.fromJson(Map<String, dynamic> json) {
    return ReportAttachment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      url: json['url']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'image/jpeg',
    );
  }

  @override
  List<Object?> get props => [id, url];
}

/// Domain model for an official report (`ReportResource`).
class Report extends Equatable {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.status,
    required this.createdAt,
    this.publicCode = '',
    this.attachments = const [],
    this.latitude,
    this.longitude,
    this.addressText,
    this.timeline = const [],
  });

  final int id;
  final String publicCode;
  final String title;
  final String description;
  final String categoryName;
  final ReportStatus status;
  final DateTime createdAt;
  final List<ReportAttachment> attachments;
  final double? latitude;
  final double? longitude;
  final String? addressText;
  final List<TimelineEntry> timeline;

  factory Report.fromJson(Map<String, dynamic> json) {
    // Unwrap {"data": {...}} if present
    final raw = (json['data'] is Map ? json['data'] : json) as Map<String, dynamic>;

    final categoryObj = raw['category'];
    final categoryName = categoryObj is Map
        ? categoryObj['name']?.toString() ?? ''
        : raw['category_name']?.toString() ?? '';

    // Field is status_history in ReportResource (detail endpoint).
    final rawTimeline = raw['status_history'] ?? raw['timeline'];
    final timeline = rawTimeline is List
        ? rawTimeline.whereType<Map<String, dynamic>>().map(TimelineEntry.fromJson).toList()
        : <TimelineEntry>[];

    final rawAttachments = raw['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments.whereType<Map<String, dynamic>>().map(ReportAttachment.fromJson).toList()
        : <ReportAttachment>[];

    return Report(
      id: _parseInt(raw['id']) ?? 0,
      publicCode: raw['public_code']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      description: raw['description']?.toString() ?? '',
      categoryName: categoryName,
      status: ReportStatus.fromString(raw['status']?.toString()),
      createdAt: DateTime.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now(),
      attachments: attachments,
      latitude: _parseDouble(raw['location']?['latitude']) ?? _parseDouble(raw['latitude']),
      longitude: _parseDouble(raw['location']?['longitude']) ?? _parseDouble(raw['longitude']),
      addressText: raw['location']?['address_text']?.toString()
          ?? raw['address_text']?.toString(),
      timeline: timeline,
    );
  }

  static int? _parseInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  static double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  @override
  List<Object?> get props => [id, status, title];
}
