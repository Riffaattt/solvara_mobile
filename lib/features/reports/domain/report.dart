import 'package:equatable/equatable.dart';

/// Canonical status values — confirm with backend.
enum ReportStatus {
  submitted,
  underReview,
  inProgress,
  resolved,
  rejected,
  unknown;

  static ReportStatus fromString(String? value) {
    return switch (value) {
      'submitted' => submitted,
      'under_review' => underReview,
      'in_progress' => inProgress,
      'resolved' => resolved,
      'rejected' => rejected,
      _ => unknown,
    };
  }

  String get label => switch (this) {
        submitted => 'Dikirim',
        underReview => 'Ditinjau',
        inProgress => 'Diproses',
        resolved => 'Selesai',
        rejected => 'Ditolak',
        unknown => 'Tidak diketahui',
      };
}

/// Canonical category values — confirm with backend.
enum ReportCategory {
  roadDamage,
  waste,
  drainage,
  streetlight,
  publicFacility,
  other;

  static ReportCategory fromString(String? value) {
    return switch (value) {
      'road_damage' => roadDamage,
      'waste' => waste,
      'drainage' => drainage,
      'streetlight' => streetlight,
      'public_facility' => publicFacility,
      _ => other,
    };
  }

  String get label => switch (this) {
        roadDamage => 'Jalan Rusak',
        waste => 'Sampah',
        drainage => 'Drainase',
        streetlight => 'Lampu Jalan',
        publicFacility => 'Fasilitas Umum',
        other => 'Lainnya',
      };

  /// The string key expected by the backend.
  String get apiValue => switch (this) {
        roadDamage => 'road_damage',
        waste => 'waste',
        drainage => 'drainage',
        streetlight => 'streetlight',
        publicFacility => 'public_facility',
        other => 'other',
      };
}

/// A single entry in the report timeline (status update from staff).
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
    return TimelineEntry(
      status: ReportStatus.fromString(json['status']?.toString()),
      note: json['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [status, note, createdAt];
}

/// Domain model for a citizen report.
class Report extends Equatable {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.photoUrls = const [],
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.timeline = const [],
  });

  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final DateTime createdAt;
  final List<String> photoUrls;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final List<TimelineEntry> timeline;

  factory Report.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'];
    final timeline = rawTimeline is List
        ? rawTimeline
            .whereType<Map<String, dynamic>>()
            .map(TimelineEntry.fromJson)
            .toList()
        : <TimelineEntry>[];

    final rawPhotos = json['photo_urls'];
    final photoUrls = rawPhotos is List
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    return Report(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: ReportCategory.fromString(json['category']?.toString()),
      status: ReportStatus.fromString(json['status']?.toString()),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      photoUrls: photoUrls,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['location_address']?.toString(),
      timeline: timeline,
    );
  }

  @override
  List<Object?> get props => [id, status, title];
}
