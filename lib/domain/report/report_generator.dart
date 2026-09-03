import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/utils/date_util.dart';
import '../../core/utils/id_util.dart';
import '../../data/local/app_database.dart';

/// 周报聚合 + 生成 + 落库。可在后台 isolate 独立运行（只依赖传入的 AppDatabase）。
///
/// 聚合口径：按 eventDate / readDate 归属到 [weekStart, weekEnd)（技术方案 §6.2）；
/// 幂等：以 weekStart 唯一去重，已存在则跳过（补偿生成用）。
class ReportGenerator {
  ReportGenerator(this._db, this._apiKey);

  final AppDatabase _db;

  // 保留 API Key 供接入 LLM；MVP 无 Key 时走本地模板降级，不阻断生成。
  // ignore: unused_field
  final String? _apiKey;

  /// 生成指定周（weekStart 为周一 00:00）的周报。已存在则跳过，返回是否新建。
  Future<bool> generateForWeek(DateTime weekStart, {bool force = false}) async {
    final start = DateUtil.startOfDay(weekStart);
    final end = DateUtil.endOfWeek(start);

    final existing = await (_db.select(_db.weeklyReports)
          ..where((t) =>
              t.weekStart.equals(start) & t.isDeleted.equals(false)))
        .getSingleOrNull();
    if (existing != null && !force) return false; // 幂等跳过

    // ---- 聚合 ----
    final dailies = await (_db.select(_db.dailyRecords)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.eventDate.isBiggerOrEqualValue(start) &
              t.eventDate.isSmallerThanValue(end)))
        .get();
    final logs = await (_db.select(_db.readingLogs)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.readDate.isBiggerOrEqualValue(start) &
              t.readDate.isSmallerThanValue(end)))
        .get();
    final extras = await (_db.select(_db.scheduleItems)
          ..where((t) =>
              t.isDeleted.equals(false) & t.type.equals('extra')))
        .get();

    final dailyCount = dailies.length;
    final readingCount = logs.length;
    final readingMinutes =
        logs.fold<int>(0, (s, l) => s + l.durationMinutes);
    final extraClassCount = extras.length;

    final activeDaySet = <String>{};
    for (final d in dailies) {
      activeDaySet.add(DateUtil.formatDate(d.eventDate));
    }
    for (final l in logs) {
      activeDaySet.add(DateUtil.formatDate(l.readDate));
    }
    final activeDays = activeDaySet.length;

    final summary = jsonEncode({
      'dailyCount': dailyCount,
      'readingCount': readingCount,
      'readingMinutes': readingMinutes,
      'extraClassCount': extraClassCount,
      'activeDays': activeDays,
      'highlights': dailies.take(5).map((d) => d.title).toList(),
    });

    // ---- 生成正文（MVP：本地模板；接入 LLM 时用 _apiKey 走 dio 生成后替换）----
    final aiText = _fallbackText(
      start: start,
      dailyCount: dailyCount,
      readingCount: readingCount,
      readingMinutes: readingMinutes,
      activeDays: activeDays,
    );

    final now = DateTime.now();
    // ---- 落库 ----
    if (existing != null) {
      await (_db.update(_db.weeklyReports)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        WeeklyReportsCompanion(
          summary: Value(summary),
          aiText: Value(aiText),
          dailyCount: Value(dailyCount),
          readingCount: Value(readingCount),
          readingMinutes: Value(readingMinutes),
          extraClassCount: Value(extraClassCount),
          activeDays: Value(activeDays),
          generatedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _db.into(_db.weeklyReports).insert(
            WeeklyReportsCompanion.insert(
              uuid: genUuid(),
              weekStart: start,
              weekEnd: end,
              summary: summary,
              aiText: Value(aiText),
              status: const Value('draft'),
              dailyCount: Value(dailyCount),
              readingCount: Value(readingCount),
              readingMinutes: Value(readingMinutes),
              extraClassCount: Value(extraClassCount),
              activeDays: Value(activeDays),
              generatedAt: now,
              updatedAt: now,
            ),
          );
    }
    return true;
  }

  /// 补偿生成：扫描最近 N 周应生成而缺失的周报并逐周补齐（幂等，技术方案 §6.3）。
  Future<int> backfillRecentWeeks({int weeks = 8}) async {
    var created = 0;
    final thisWeek = DateUtil.startOfThisWeek();
    for (var i = 1; i <= weeks; i++) {
      final ws = thisWeek.subtract(Duration(days: 7 * i));
      if (await generateForWeek(ws)) created++;
    }
    return created;
  }

  String _fallbackText({
    required DateTime start,
    required int dailyCount,
    required int readingCount,
    required int readingMinutes,
    required int activeDays,
  }) {
    final wk = DateUtil.formatDate(start);
    return '本周（$wk 起）孩子共有 $activeDays 天留下成长记录：'
        '日常 $dailyCount 条、阅读打卡 $readingCount 次、'
        '累计阅读 $readingMinutes 分钟。继续陪伴，静待花开 🌱';
  }
}
