import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat _ymdHm = DateFormat('yyyy-MM-dd HH:mm');

  static String formatDate(DateTime date) => _ymd.format(date);

  static String formatDateTime(DateTime date) => _ymdHm.format(date);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfWeek(DateTime date) {
    final d = startOfDay(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
