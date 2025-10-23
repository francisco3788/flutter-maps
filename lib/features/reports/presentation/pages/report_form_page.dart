import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/report_media.dart';
import '../../data/reports_repository.dart';
import '../../domain/report.dart';
import '../controllers/reports_controller.dart';

class ReportFormArgs {
  ReportFormArgs({
    this.initialPoint,
    this.report,
  });

  final LatLng? initialPoint;
  final Report? report;
}

class ReportFormPage extends ConsumerStatefulWidget {
  const ReportFormPage({super.key, this.args});

  static const route = '/reports/new';

  final ReportFormArgs? args;

  @override
  ConsumerState<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends ConsumerState<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  ReportType _type = ReportType.bache;
  ReportSeverity _severity = ReportSeverity.media;
  ReportStatus _status = ReportStatus.abierto;
  ReportMedia? _media;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final report = widget.args?.report;
    if (report != null) {
      _isEditing = true;
      _type = report.type;
      _severity = report.severity;
      _status = report.status;
      _descriptionController.text = report.description ?? '';
      _latController.text = report.lat.toStringAsFixed(6);
      _lngController.text = report.lng.toStringAsFixed(6);
    } else {
      final point = widget.args?.initialPoint;
      if (point != null) {
        _latController.text = point.latitude.toStringAsFixed(6);
        _lngController.text = point.longitude.toStringAsFixed(6);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(reportActionsControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar reporte' : 'Nuevo reporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ReportType>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo de daÃ±o'),
                items: ReportType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportSeverity>(
                // ignore: deprecated_member_use
                value: _severity,
                decoration: const InputDecoration(labelText: 'Severidad'),
                items: ReportSeverity.values
                    .map((severity) => DropdownMenuItem(
                          value: severity,
                          child: Text(severityLabel(severity)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _severity = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportStatus>(
                // ignore: deprecated_member_use
                value: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ReportStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(statusLabel(status)),
                        ))
                    .toList(),
                onChanged: _isEditing
                    ? (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'DescripciÃ³n',
                  alignLabelWithHint: true,
                ),
                validator: ReportValidators.validateDescription,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      validator: ReportValidators.validateLatitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitud'),
                      validator: ReportValidators.validateLongitude,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isProcessing ? null : _pickMedia,
                icon: const Icon(Icons.camera_alt),
                label: Text(_media == null ? 'Adjuntar foto' : _media!.fileName),
              ),
              const SizedBox(height: 8),
              Text(
                'Formatos: JPG, PNG, WEBP (mÃ¡x. 5 MB)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isProcessing ? null : _submit,
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear reporte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    final media = await pickReportMedia();
    if (media == null) return;
    if (media.bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      showAppSnackBar(context, 'La imagen supera 5 MB', isError: true);
      return;
    }
    setState(() {
      _media = media;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final lat = double.parse(_latController.text);
    final lng = double.parse(_lngController.text);

    final draft = ReportDraft(
      type: _type,
      severity: _severity,
      status: _status,
      description: _descriptionController.text.trim(),
      lat: lat,
      lng: lng,
    );

    final controller = ref.read(reportActionsControllerProvider.notifier);
    final result = _isEditing && widget.args?.report != null
        ? await controller.updateReport(
            report: widget.args!.report!,
            draft: draft,
            media: _media,
          )
        : await controller.createReport(
            draft: draft,
            media: _media,
          );

    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(reportsProvider);
        Navigator.of(context).pop(true);
      },
      failure: (error, _) {
        final message = error is PostgrestException ? error.message : '$error';
        showAppSnackBar(context, message, isError: true);
      },
    );
  }
}

