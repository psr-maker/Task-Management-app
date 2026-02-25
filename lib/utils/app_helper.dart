class AppHelpers {
  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
  }

  static String formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    return date.split('T').first;
  }

  static String extractName(String? value) {
    if (value == null || value.isEmpty) return "N/A";
    final parts = value.split('-');
    return parts.length > 1 ? parts.sublist(1).join('-') : value;
  }
}
