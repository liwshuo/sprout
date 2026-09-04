import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../core/utils/id_util.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 日常事项仓库。按 eventDate 聚合（支持补填过去某天）。
class DailyRepository {
  DailyRepository(this._db);

  final AppDatabase _db;

  Stream<List<DailyRecord>> watchAll() => (_db.select(_db.dailyRecords)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
      .watch();

  /// 按事件发生日聚合（日历下钻 / 当日详情）。
  Future<List<DailyRecord>> fetchByDate(DateTime day) {
    final start = DateUtil.startOfDay(day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.dailyRecords)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.eventDate.isBiggerOrEqualValue(start) &
              t.eventDate.isSmallerThanValue(end)))
        .get();
  }

  /// 按区间聚合（周报 [weekStart, weekEnd)）。
  Future<List<DailyRecord>> fetchByRange(DateTime start, DateTime end) {
    return (_db.select(_db.dailyRecords)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.eventDate.isBiggerOrEqualValue(start) &
              t.eventDate.isSmallerThanValue(end)))
        .get();
  }

  Future<int> add(DailyRecordsCompanion entry) =>
      _db.into(_db.dailyRecords).insert(entry);

  /// 便捷方法：自动补 uuid / createdAt / updatedAt。
  Future<int> addFields({
    required String title,
    String? note,
    String? tags,
    String? imagePaths,
    String? category,
    String? mood,
    String source = 'manual',
    required DateTime eventDate,
    int? durationMinutes,
  }) {
    final now = DateTime.now();
    return add(
      DailyRecordsCompanion.insert(
        uuid: genUuid(),
        title: title,
        note: Value(note),
        tags: Value(tags),
        imagePaths: Value(imagePaths),
        category: Value(category),
        mood: Value(mood),
        source: Value(source),
        eventDate: eventDate,
        durationMinutes: Value(durationMinutes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> update(DailyRecord entry) =>
      _db.update(_db.dailyRecords).replace(
            entry.copyWith(updatedAt: DateTime.now()),
          );

  Future<int> remove(int id) =>
      (_db.update(_db.dailyRecords)..where((t) => t.id.equals(id))).write(
        DailyRecordsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

final dailyRepositoryProvider = Provider<DailyRepository>(
  (ref) => DailyRepository(ref.watch(appDatabaseProvider)),
);
