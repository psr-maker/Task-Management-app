class TimeUtils {
  /// Convert ISO8601 UTC string to local DateTime
  /// 
  /// Handles various ISO8601 formats:
  /// - "2026-09-02T04:46:21Z"
  /// - "2026-09-02T04:46:21.414209Z"
  /// - "2026-09-02T04:46:21"
  /// - "2026-09-02 04:46:21"
  static DateTime fromUtcIso8601(String value) {
    try {
      // Normalize the input
      String normalized = value.trim();
      
      // Replace space with T for standard ISO8601
      if (normalized.contains(' ') && !normalized.contains('T')) {
        normalized = normalized.replaceFirst(' ', 'T');
      }
      
      // Ensure Z suffix for UTC indicator
      if (!normalized.endsWith('Z') && !normalized.contains('+')) {
        normalized = '${normalized}Z';
      }
      
      // Parse as UTC
      final utcDateTime = DateTime.parse(normalized).toUtc();
      
      // Convert to local time
      final localDateTime = utcDateTime.toLocal();
      
      return localDateTime;
    } catch (e) {
      // Return current local time as fallback
      return DateTime.now();
    }
  }

  /// Convert local DateTime to UTC ISO8601 string
  static String toUtcIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Convert local DateTime to UTC ISO8601 string with logging
  static String toUtcIso8601WithLog(DateTime dateTime, String label) {
    final localTimeStr = dateTime.toIso8601String();
    final utcTimeStr = dateTime.toUtc().toIso8601String();
    print("🕐 [$label] Local: $localTimeStr → UTC: $utcTimeStr");
    return utcTimeStr;
  }

  /// Format time difference in human-readable format
  static String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    
    if (hours == 0) {
      return "${minutes}m";
    } else if (minutes == 0) {
      return "${hours}h";
    } else {
      return "${hours}h ${minutes}m";
    }
  }
}
