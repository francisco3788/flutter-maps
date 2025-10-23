import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/report.dart';
import '../controllers/reports_controller.dart';
import 'report_form_page.dart';
import 'report_detail_page.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = LocationService.fallback;
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    final position = await LocationService.currentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() {
        _center = position;
        _locationLoaded = true;
      });
      _mapController.move(position, 15);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final filters = ref.watch(reportFiltersProvider);

    return Stack(
      children: [
        reportsAsync.when(
          data: (reports) => FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onLongPress: (_, point) => _openNewReport(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.maps',
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.never,
                alignDirectionOnUpdate: AlignOnUpdate.never,
              ),
              MarkerLayer(
                markers: reports.map(_buildMarker).toList(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('Datos (c) OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error cargando reportes: $error'),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _FiltersCard(filters: filters),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _locationLoaded ? () => _openNewReport(_center) : _handleNewReportWithLocation,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNewReportWithLocation() async {
    final position = await LocationService.currentPosition();
    final point = position ?? LocationService.fallback;
    if (!mounted) return;
    _openNewReport(point);
  }

  Future<void> _openNewReport(LatLng point) async {
    final created = await Navigator.of(context).pushNamed(
      ReportFormPage.route,
      arguments: ReportFormArgs(initialPoint: point),
    );
    if (created == true && mounted) {
      showAppSnackBar(context, 'Reporte enviado');
    }
  }

  Marker _buildMarker(Report report) {
    final color = severityColor(report.severity);
    return Marker(
      width: 60,
      height: 60,
      point: report.point,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          ReportDetailPage.route,
          arguments: report.id,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                severityLabel(report.severity),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.location_on,
              color: color,
              size: report.status == ReportStatus.abierto ? 36 : 30,
              shadows: report.status == ReportStatus.abierto
                  ? [
                      Shadow(
                        color: color.withAlpha((0.4 * 255).round()),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersCard extends ConsumerWidget {
  const _FiltersCard({required this.filters});

  final ReportFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reportFiltersProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: filters.type == null && filters.severity == null && filters.status == null,
                    onSelected: (_) => notifier.clear(),
                  ),
                  const SizedBox(width: 8),
                  ...ReportType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.label),
                        selected: filters.type == type,
                        onSelected: (selected) => notifier.setType(selected ? type : null),
                      ),
                    ),
                  ),
                  ...ReportSeverity.values.map(
                    (severity) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(severityLabel(severity)),
                        selected: filters.severity == severity,
                        onSelected: (selected) => notifier.setSeverity(selected ? severity : null),
                      ),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}


