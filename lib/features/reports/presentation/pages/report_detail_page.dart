import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/report.dart';
import '../controllers/reports_controller.dart';
import 'report_form_page.dart';

class ReportDetailPage extends ConsumerWidget {
  const ReportDetailPage({super.key, required this.reportId});

  static const route = '/reports/detail';

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));
    final actions = ref.watch(reportActionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reporte'),
        actions: reportAsync.maybeWhen(
          data: (report) => [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _handleEdit(context, ref, report),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: actions.isLoading ? null : () => _handleDelete(context, ref, report),
            ),
          ],
          orElse: () => [],
        ),
      ),
      body: reportAsync.when(
        data: (report) => _ReportDetailBody(
          report: report,
          isProcessing: actions.isLoading,
          onClose: () => _handleClose(context, ref, report),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('No se pudo cargar el reporte: $error')),
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref, Report report) async {
    final updated = await Navigator.of(context).pushNamed(
      ReportFormPage.route,
      arguments: ReportFormArgs(report: report),
    );
    if (updated == true) {
      ref.invalidate(reportDetailProvider(report.id));
      ref.invalidate(reportsProvider);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text('Â¿Deseas eliminar este reporte de forma permanente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ref.read(reportActionsControllerProvider.notifier).deleteReport(report.id);
    result.when(
      success: (_) {
        ref.invalidate(reportsProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          showAppSnackBar(context, 'Reporte eliminado');
        }
      },
      failure: (error, _) {
        if (context.mounted) {
          showAppSnackBar(context, '$error', isError: true);
        }
      },
    );
  }

  Future<void> _handleClose(BuildContext context, WidgetRef ref, Report report) async {
    final result = await ref.read(reportActionsControllerProvider.notifier).closeReport(report.id);
    result.when(
      success: (_) {
        ref.invalidate(reportDetailProvider(report.id));
        ref.invalidate(reportsProvider);
        if (context.mounted) {
          showAppSnackBar(context, 'Reporte cerrado');
        }
      },
      failure: (error, _) {
        if (context.mounted) {
          showAppSnackBar(context, '$error', isError: true);
        }
      },
    );
  }
}

class _ReportDetailBody extends StatelessWidget {
  const _ReportDetailBody({
    required this.report,
    required this.onClose,
    required this.isProcessing,
  });

  final Report report;
  final VoidCallback onClose;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final entries = <_DetailEntry>[
      _DetailEntry(label: 'Tipo', value: report.type.label),
      _DetailEntry(label: 'Severidad', value: severityLabel(report.severity)),
      _DetailEntry(label: 'Estado', value: statusLabel(report.status)),
      _DetailEntry(label: 'Coordenadas', value: '${report.lat}, ${report.lng}'),
      _DetailEntry(label: 'Creado', value: dateFormat.format(report.createdAt.toLocal())),
      if (report.closedAt != null)
        _DetailEntry(label: 'Cerrado', value: dateFormat.format(report.closedAt!.toLocal())),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  report.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text('No se pudo cargar la imagen')),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            report.description ?? 'Sin descripciÃ³n',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (report.status == ReportStatus.abierto) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isProcessing ? null : onClose,
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Marcar como cerrado'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailEntry {
  _DetailEntry({required this.label, required this.value});

  final String label;
  final String value;
}
