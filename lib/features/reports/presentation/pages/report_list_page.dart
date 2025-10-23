import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/report.dart';
import '../controllers/reports_controller.dart';
import 'report_detail_page.dart';
import 'report_form_page.dart';

class ReportListPage extends ConsumerStatefulWidget {
  const ReportListPage({super.key});

  @override
  ConsumerState<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends ConsumerState<ReportListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final filters = ref.watch(reportFiltersProvider);
    final notifier = ref.read(reportFiltersProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por descripciÃ³n',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filters.query != null && filters.query!.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setQuery(null);
                      },
                    )
                  : null,
            ),
            onChanged: notifier.setQuery,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos los estados'),
                selected: filters.status == null,
                onSelected: (_) => notifier.setStatus(null),
              ),
              const SizedBox(width: 8),
              ...ReportStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(statusLabel(status)),
                    selected: filters.status == status,
                    onSelected: (selected) => notifier.setStatus(selected ? status : null),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _ReportTile(
                    report: report,
                    onTap: () => Navigator.of(context).pushNamed(
                      ReportDetailPage.route,
                      arguments: report.id,
                    ),
                    onEdit: () => Navigator.of(context).pushNamed(
                      ReportFormPage.route,
                      arguments: ReportFormArgs(report: report),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: reports.length,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('No se pudo cargar la lista: $error')),
          ),
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.report,
    required this.onTap,
    required this.onEdit,
  });

  final Report report;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(report.severity);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(((0.15) * 255).round()),
          child: Icon(Icons.warning, color: color),
        ),
        title: Text(
          report.description ?? 'Sin descripciÃ³n',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${report.type.label} â€¢ ${severityLabel(report.severity)} â€¢ ${statusLabel(report.status)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin reportes por ahora',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un nuevo reporte desde el mapa o el botÃ³n +',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

