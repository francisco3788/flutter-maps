import 'package:latlong2/latlong.dart';

enum ReportType {
  bache('Bache'),
  hundimiento('Hundimiento'),
  grieta('Grieta'),
  tapaAlcantarilla('Tapa alcantarilla'),
  otro('Otro');

  const ReportType(this.label);
  final String label;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (e) => e.name == value || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ReportType.otro,
    );
  }

  String toStorage() => name;
}

enum ReportSeverity { baja, media, alta, critica }

enum ReportStatus { abierto, cerrado }

class Report {
  const Report({
    required this.id,
    required this.userId,
    required this.type,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.description,
    this.photoUrl,
    this.closedAt,
  });

  final String id;
  final String? userId;
  final ReportType type;
  final ReportSeverity severity;
  final ReportStatus status;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? description;
  final String? photoUrl;

  LatLng get point => LatLng(lat, lng);

  Report copyWith({
    String? id,
    String? userId,
    ReportType? type,
    ReportSeverity? severity,
    ReportStatus? status,
    double? lat,
    double? lng,
    DateTime? createdAt,
    DateTime? closedAt,
    String? description,
    String? photoUrl,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      type: ReportType.fromString(map['type'] as String),
      severity: ReportSeverity.values.firstWhere(
        (e) => e.name == (map['severity'] as String).toLowerCase(),
        orElse: () => ReportSeverity.media,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String).toLowerCase(),
        orElse: () => ReportStatus.abierto,
      ),
      description: map['description'] as String?,
      photoUrl: map['photo_url'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toStorage(),
      'severity': severity.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'description': description,
      'photo_url': photoUrl,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }
}

class ReportFilters {
  const ReportFilters({
    this.type,
    this.severity,
    this.status,
    this.query,
  });

  final ReportType? type;
  final ReportSeverity? severity;
  final ReportStatus? status;
  final String? query;

  ReportFilters copyWith({
    ReportType? type,
    ReportSeverity? severity,
    ReportStatus? status,
    String? query,
  }) {
    return ReportFilters(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      query: query ?? this.query,
    );
  }
}
