import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat _ymdHm = DateFormat('yyyy-MM-dd HH:mm');

  static String formatDate(DateTime date) => _ymd.format(date);

  static String formatDateTime(DateTime date) => _ymdHm.format(date);

  static DateTime parseDate(String s) => _ymd.parse(s);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 周一 00:00。
  static DateTime startOfWeek(DateTime date) {
    final d = startOfDay(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// 本周周一 00:00。
  static DateTime startOfThisWeek() => startOfWeek(DateTime.now());

  /// 给定周起点对应的周终点（下周一 00:00，区间半开 [weekStart, weekEnd)）。
  static DateTime endOfWeek(DateTime weekStart) =>
      startOfDay(weekStart).add(const Duration(days: 7));

  /// 月首日 00:00。
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);
}
