import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_client.dart';
import '../domain/report.dart';
import 'report_media.dart';

const _reportsTable = 'reports';
const _bucketName = 'road_reports';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref),
);

class ReportsRepository {
  ReportsRepository(this._ref);

  final Ref _ref;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<List<Report>> fetchReports({ReportFilters? filters}) async {
    final result = await _client
        .from(_reportsTable)
        .select()
        .order('created_at', ascending: false);
    final rows = (result as List).cast<Map<String, dynamic>>();
    final reports = rows.map(Report.fromMap).toList();
    return _filterReports(reports, filters);
  }

  Future<Report> insertReport({
    required String userId,
    required ReportDraft draft,
    ReportMedia? media,
  }) async {
    final payload = draft.toInsertMap(userId: userId);
    final response = await _client.from(_reportsTable).insert(payload).select().single();
    var report = Report.fromMap(Map<String, dynamic>.from(response as Map));
    if (media != null) {
      final photoUrl = await uploadReportPhoto(
        userId: userId,
        reportId: report.id,
        media: media,
      );
      report = await _updatePhoto(report.id, photoUrl);
    }
    return report;
  }

  Future<Report> updateReport({
    required Report report,
    required ReportDraft draft,
    ReportMedia? media,
  }) async {
    final updates = draft.toUpdateMap();
    if (media != null && report.userId != null) {
      final photoUrl = await uploadReportPhoto(
        userId: report.userId!,
        reportId: report.id,
        media: media,
      );
      updates['photo_url'] = photoUrl;
    }
    final response = await _client
        .from(_reportsTable)
        .update(updates)
        .eq('id', report.id)
        .select()
        .single();
    return Report.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<void> deleteReport(String id) async {
    await _client.from(_reportsTable).delete().eq('id', id);
  }

  Future<Report> closeReport(String id) async {
    final response = await _client
        .from(_reportsTable)
        .update({
          'status': ReportStatus.cerrado.name.toUpperCase(),
          'closed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Report.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<String> uploadReportPhoto({
    required String userId,
    required String reportId,
    required ReportMedia media,
  }) async {
    final path = '$userId/$reportId${_extensionFromMime(media.contentType)}';
    await _client.storage.from(_bucketName).uploadBinary(
          path,
          media.bytes,
          fileOptions: FileOptions(
            contentType: media.contentType,
            upsert: true,
          ),
        );
    return _client.storage.from(_bucketName).getPublicUrl(path);
  }

  Future<Report> getById(String id) async {
    final response =
        await _client.from(_reportsTable).select().eq('id', id).maybeSingle();
    if (response == null) {
      throw StateError('Reporte no encontrado');
    }
    return Report.fromMap(Map<String, dynamic>.from(response as Map));
  }

  List<Report> _filterReports(List<Report> reports, ReportFilters? filters) {
    if (filters == null) {
      return reports;
    }
    return reports.where((report) {
      if (filters.type != null && report.type != filters.type) {
        return false;
      }
      if (filters.severity != null && report.severity != filters.severity) {
        return false;
      }
      if (filters.status != null && report.status != filters.status) {
        return false;
      }
      final query = filters.query?.trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        final text = (report.description ?? '').toLowerCase();
        if (!text.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<Report> _updatePhoto(String id, String photoUrl) async {
    final response = await _client
        .from(_reportsTable)
        .update({'photo_url': photoUrl})
        .eq('id', id)
        .select()
        .single();
    return Report.fromMap(Map<String, dynamic>.from(response as Map));
  }

  String _extensionFromMime(String mime) {
    if (mime == 'image/png') return '.png';
    if (mime == 'image/webp') return '.webp';
    if (mime == 'image/heic') return '.heic';
    return '.jpg';
  }
}

class ReportDraft {
  const ReportDraft({
    required this.type,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    this.description,
  });

  final ReportType type;
  final ReportSeverity severity;
  final ReportStatus status;
  final double lat;
  final double lng;
  final String? description;

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'user_id': userId,
      ..._commonMap(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return _commonMap();
  }

  Map<String, dynamic> _commonMap() {
    return {
      'type': type.name,
      'severity': severity.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'description': description,
      'lat': lat,
      'lng': lng,
    };
  }
}
