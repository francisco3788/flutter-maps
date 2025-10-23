class ReportValidators {
  static String? validateLatitude(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return 'Latitud requerida';
    }
    final lat = double.tryParse(text);
    if (lat == null || lat < -90 || lat > 90) {
      return 'Latitud inválida';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return 'Longitud requerida';
    }
    final lng = double.tryParse(text);
    if (lng == null || lng < -180 || lng > 180) {
      return 'Longitud inválida';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Descripción requerida';
    }
    if (text.length < 10) {
      return 'Describe el daño con al menos 10 caracteres';
    }
    return null;
  }
}
