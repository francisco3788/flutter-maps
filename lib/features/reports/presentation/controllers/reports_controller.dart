import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/reports_repository.dart';
import '../../data/report_media.dart';
import '../../domain/report.dart';
import '../../../../core/utils/result.dart';

final reportFiltersProvider =
    StateNotifierProvider<ReportFiltersNotifier, ReportFilters>((ref) {
  return ReportFiltersNotifier();
});

final reportsProvider = FutureProvider.autoDispose<List<Report>>((ref) {
  final filters = ref.watch(reportFiltersProvider);
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.fetchReports(filters: filters);
});

final reportsStatsProvider = FutureProvider.autoDispose<ReportsStats>((ref) async {
  final reports = await ref.watch(reportsProvider.future);
  final abiertos = reports.where((r) => r.status == ReportStatus.abierto).length;
  final cerrados = reports.length - abiertos;
  final total = reports.length;
  final porcentajeCerrados = total == 0 ? 0.0 : (cerrados / total);
  final severidad = <ReportSeverity, int>{
    for (final severity in ReportSeverity.values) severity: 0,
  };
  for (final report in reports) {
    severidad[report.severity] = (severidad[report.severity] ?? 0) + 1;
  }
  return ReportsStats(
    abiertos: abiertos,
    cerrados: cerrados,
    porcentajeCerrados: porcentajeCerrados,
    severidadCount: severidad,
  );
});

final reportActionsControllerProvider =
    AutoDisposeAsyncNotifierProvider<ReportActionsController, void>(
  ReportActionsController.new,
);

final reportDetailProvider =
    FutureProvider.autoDispose.family<Report, String>((ref, id) {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.getById(id);
});

class ReportFiltersNotifier extends StateNotifier<ReportFilters> {
  ReportFiltersNotifier() : super(const ReportFilters());

  void setType(ReportType? type) => state = state.copyWith(type: type);
  void setSeverity(ReportSeverity? severity) => state = state.copyWith(severity: severity);
  void setStatus(ReportStatus? status) => state = state.copyWith(status: status);
  void setQuery(String? query) => state = state.copyWith(query: query);
  void clear() => state = const ReportFilters();
}

class ReportsStats {
  ReportsStats({
    required this.abiertos,
    required this.cerrados,
    required this.porcentajeCerrados,
    required this.severidadCount,
  });

  final int abiertos;
  final int cerrados;
  final double porcentajeCerrados;
  final Map<ReportSeverity, int> severidadCount;
}

class ReportActionsController extends AutoDisposeAsyncNotifier<void> {
  ReportsRepository get _repository => ref.read(reportsRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<Result<Report>> createReport({
    required ReportDraft draft,
    ReportMedia? media,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final user = await ref.read(authControllerProvider.future);
      if (user == null) {
        throw StateError('Sesion invalida');
      }
      return _repository.insertReport(
        userId: user.id,
        draft: draft,
        media: media,
      );
    });
    state = const AsyncData(null);
    return result.when(
      data: (data) => Success(data),
      error: (error, stackTrace) => Failure(error, stackTrace),
      loading: () => const Failure('Operacion en curso', StackTrace.empty),
    );
  }

  Future<Result<Report>> updateReport({
    required Report report,
    required ReportDraft draft,
    ReportMedia? media,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      return _repository.updateReport(
        report: report,
        draft: draft,
        media: media,
      );
    });
    state = const AsyncData(null);
    return result.when(
      data: (data) => Success(data),
      error: (error, stackTrace) => Failure(error, stackTrace),
      loading: () => const Failure('Operacion en curso', StackTrace.empty),
    );
  }

  Future<Result<void>> deleteReport(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await _repository.deleteReport(id);
      return null;
    });
    state = const AsyncData(null);
    return result.when(
      data: (_) => const Success(null),
      error: (error, stackTrace) => Failure(error, stackTrace),
      loading: () => const Failure('Operacion en curso', StackTrace.empty),
    );
  }

  Future<Result<Report>> closeReport(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repository.closeReport(id));
    state = const AsyncData(null);
    return result.when(
      data: (data) => Success(data),
      error: (error, stackTrace) => Failure(error, stackTrace),
      loading: () => const Failure('Operacion en curso', StackTrace.empty),
    );
  }
}
