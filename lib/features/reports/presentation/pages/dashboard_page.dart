import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/report.dart';
import '../controllers/reports_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reportsStatsProvider);
    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tablero de VÃ­a Limpia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _KpiRow(stats: stats),
            const SizedBox(height: 24),
            _CompletionCard(stats: stats),
            const SizedBox(height: 24),
            _SeverityChart(stats: stats),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('No se pudo cargar el tablero: $error')),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.stats});

  final ReportsStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Reportes abiertos',
            value: stats.abiertos.toString(),
            color: Colors.orange[600]!,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Reportes cerrados',
            value: stats.cerrados.toString(),
            color: Colors.green[600]!,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.stats});

  final ReportsStats stats;

  @override
  Widget build(BuildContext context) {
    final percentage = (stats.porcentajeCerrados * 100).toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Porcentaje de cierre', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: stats.porcentajeCerrados,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 8),
            Text('$percentage% de los reportes estÃ¡n cerrados'),
          ],
        ),
      ),
    );
  }
}

class _SeverityChart extends StatelessWidget {
  const _SeverityChart({required this.stats});

  final ReportsStats stats;

  @override
  Widget build(BuildContext context) {
    final maxValue = stats.severidadCount.values.fold<int>(1, (prev, element) => element > prev ? element : prev);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reportes por severidad', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ReportSeverity.values.map((severity) {
                  final value = stats.severidadCount[severity] ?? 0;
                  final heightFactor = value == 0 ? 0.05 : value / maxValue;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 36,
                              height: 180 * heightFactor,
                              decoration: BoxDecoration(
                                color: severityColor(severity).withAlpha(((0.8) * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(severityLabel(severity)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
