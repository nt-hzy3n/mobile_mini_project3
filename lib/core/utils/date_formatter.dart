import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDayFormat = DateFormat('dd/MM');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');

  static String format(DateTime date) {
    return _dayFormat.format(date);
  }

  static String formatWithTime(DateTime date) {
    return _dayTimeFormat.format(date);
  }

  static String formatShort(DateTime date) {
    return _shortDayFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) {
      return 'Hôm nay';
    } else if (diff == 1) {
      return 'Hôm qua';
    } else if (diff > 1 && diff <= 7) {
      return '$diff ngày trước';
    } else {
      return _dayFormat.format(date);
    }
  }

  static DateTime? tryParse(String text) {
    final clean = text.trim();
    final patterns = [
      RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$'),
      RegExp(r'^(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(clean);
      if (match != null) {
        if (pattern.pattern.startsWith('^(\\d{1,2})')) {
          final day = int.tryParse(match.group(1)!);
          final month = int.tryParse(match.group(2)!);
          final year = int.tryParse(match.group(3)!);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        } else {
          final year = int.tryParse(match.group(1)!);
          final month = int.tryParse(match.group(2)!);
          final day = int.tryParse(match.group(3)!);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
    }
    return null;
  }
}
