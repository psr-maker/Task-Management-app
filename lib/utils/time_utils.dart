import 'package:intl/intl.dart';

class TimeUtils {
  /// Turns an API timestamp into the device's local time.
  ///
  /// A value that already has Z or an offset is converted.
  /// A value with no zone is kept as that clock time. The API stores
  /// DateTime.Now without marking it as UTC, so adding Z would shift it.
  static DateTime fromUtcIso8601(String value) {
    return tryParse(value) ?? DateTime.now();
  }

  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final text = value.toString().trim();
    if (text.isEmpty || text == '-' || text == 'N/A') return null;

    try {
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
        return DateFormat('dd/MM/yyyy').parseStrict(text);
      }

      var normalized = text;
      if (normalized.contains(' ') && !normalized.contains('T')) {
        normalized = normalized.replaceFirst(' ', 'T');
      }

      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateValue(dynamic value, {String empty = '-'}) {
    final parsed = tryParse(value);
    if (parsed == null) {
      if (value == null || value.toString().trim().isEmpty) return empty;
      return value.toString();
    }
    return formatDate(parsed);
  }

  /// Worklog rows are stored in UTC with no zone, such as 07:21:00.
  /// Show that clock time in the device's local zone.
  static DateTime? worklogToLocal(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();

    final text = value.toString().trim();
    if (text.isEmpty || text == '-' || text == 'N/A') return null;

    final clock = text.toUpperCase();
    if (clock.contains('AM') || clock.contains('PM')) {
      return tryParse(text);
    }

    final timeOnly = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?$',
    ).firstMatch(text);
    if (timeOnly != null) {
      final hour = int.parse(timeOnly.group(1)!);
      final minute = int.parse(timeOnly.group(2)!);
      final second = int.tryParse(timeOnly.group(3) ?? '') ?? 0;
      if (hour > 23 || minute > 59 || second > 59) return null;
      return DateTime.utc(2000, 1, 1, hour, minute, second).toLocal();
    }

    var normalized = text;
    if (normalized.contains(' ') && !normalized.contains('T')) {
      normalized = normalized.replaceFirst(' ', 'T');
    }
    final hasZone = normalized.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(normalized) ||
        RegExp(r'[+-]\d{4}$').hasMatch(normalized);
    if (!hasZone) normalized = '${normalized}Z';

    try {
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String formatWorklogTime(dynamic value, {String empty = '--:--'}) {
    final local = worklogToLocal(value);
    if (local == null) {
      if (value == null || value.toString().trim().isEmpty) return empty;
      return formatTime12(value, empty: empty);
    }
    return DateFormat('h:mm a').format(local);
  }

  static String formatTime12(dynamic value, {String empty = '--'}) {
    if (value == null) return empty;
    final text = value.toString().trim();
    if (text.isEmpty) return empty;

    try {
      if (text.contains('T') || text.contains('-') || text.contains('/')) {
        final parsed = tryParse(text);
        if (parsed != null && (text.contains('T') || text.contains(':'))) {
          return DateFormat('h:mm a').format(parsed);
        }
      }

      final clock = text.toUpperCase();
      if (clock.contains('AM') || clock.contains('PM')) {
        final parsed = DateFormat('h:mm a').parse(text);
        return DateFormat('h:mm a').format(parsed);
      }

      final parts = text.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
      }
    } catch (_) {}

    return text;
  }

  static String toApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String toApiDateString(String text) {
    final parsed = tryParse(text);
    if (parsed == null) return text;
    return toApiDate(parsed);
  }

  static String toApiTime(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    try {
      final clock = trimmed.toUpperCase();
      if (clock.contains('AM') || clock.contains('PM')) {
        final parsed = DateFormat('h:mm a').parse(trimmed);
        return DateFormat('HH:mm:ss').format(parsed);
      }

      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length >= 3
            ? int.parse(parts[2].split('.').first)
            : 0;
        return DateFormat('HH:mm:ss').format(
          DateTime(2000, 1, 1, hour, minute, second),
        );
      }
    } catch (_) {}

    return trimmed;
  }

  static String toUtcIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static String toUtcIso8601WithLog(DateTime dateTime, String label) {
    final localTimeStr = dateTime.toIso8601String();
    final utcTimeStr = dateTime.toUtc().toIso8601String();
    print("[$label] Local: $localTimeStr -> UTC: $utcTimeStr");
    return utcTimeStr;
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return "${minutes}m";
    } else if (minutes == 0) {
      return "${hours}h";
    }
    return "${hours}h ${minutes}m";
  }
}
