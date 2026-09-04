import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import 'report_generator.dart';

const _kWeeklyTask = 'weekly_report_task';

/// 计算"现在 → 下一个周日 20:00"的延迟。
///
/// Android WorkManager 不支持 cron，且 PeriodicWorkRequest 无法精确到点，
/// 因此用 OneTimeWorkRequest + initialDelay，触发后自重排下一周（自重排链）。
Duration nextSunday20(DateTime now) {
  var t = DateTime(now.year, now.month, now.day, 20);
  final daysToSun = (DateTime.sunday - now.weekday + 7) % 7; // 周一=1..周日=7
  t = t.add(Duration(days: daysToSun));
  if (!t.isAfter(now)) t = t.add(const Duration(days: 7)); // 已过点则顺延一周
  return t.difference(now);
}

/// 注册（每次触发后回调里再次调用，形成自重排链）。
Future<void> scheduleWeekly() => Workmanager().registerOneOffTask(
      _kWeeklyTask,
      _kWeeklyTask,
      initialDelay: nextSunday20(DateTime.now()),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

/// workmanager 后台入口。运行在独立 isolate：不共享主 isolate 的 drift 连接、
/// Riverpod 容器与内存态，因此必须自行开 DB + 读 Key（技术方案 §6.2）。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    final db = AppDatabase(); // beforeOpen 内已 PRAGMA foreign_keys=ON
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('llm_api_key');
    try {
      await ReportGenerator(db, apiKey)
          .generateForWeek(DateUtil.startOfThisWeek());
    } finally {
      await db.close(); // 用完即关，避免 isolate 泄漏
      await scheduleWeekly(); // 自重排下一周
    }
    return true;
  });
}
