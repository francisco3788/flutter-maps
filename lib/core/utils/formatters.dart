import 'package:flutter/material.dart';
import '../../features/reports/domain/report.dart';

String severityLabel(ReportSeverity severity) {
  switch (severity) {
    case ReportSeverity.baja:
      return 'Baja';
    case ReportSeverity.media:
      return 'Media';
    case ReportSeverity.alta:
      return 'Alta';
    case ReportSeverity.critica:
      return 'Crítica';
  }
}

String statusLabel(ReportStatus status) {
  switch (status) {
    case ReportStatus.abierto:
      return 'Abierto';
    case ReportStatus.cerrado:
      return 'Cerrado';
  }
}

Color severityColor(ReportSeverity severity) {
  return switch (severity) {
    ReportSeverity.baja => const Color(0xFF22C55E),
    ReportSeverity.media => const Color(0xFFFACC15),
    ReportSeverity.alta => const Color(0xFFF97316),
    ReportSeverity.critica => const Color(0xFFDC2626),
  };
}
