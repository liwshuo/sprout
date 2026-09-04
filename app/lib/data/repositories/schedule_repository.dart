import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_util.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 课表仓库。每条仅存单个 weekday；"多选周几"在保存时按每个 weekday 各插一行。
class ScheduleRepository {
  ScheduleRepository(this._db);

  final AppDatabase _db;

  Stream<List<ScheduleItem>> watchAll() => (_db.select(_db.scheduleItems)
        ..where((t) => t.isDeleted.equals(false)))
      .watch();

  Future<List<ScheduleItem>> fetchByWeekday(int weekday) =>
      (_db.select(_db.scheduleItems)
            ..where((t) =>
                t.weekday.equals(weekday) & t.isDeleted.equals(false)))
          .get();

  Future<int> add(ScheduleItemsCompanion entry) =>
      _db.into(_db.scheduleItems).insert(entry);

  /// 便捷方法：一次课程可选多个 weekday，逐个落一行（共享其余字段）。
  Future<void> addForWeekdays({
    required String courseName,
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    String type = 'school',
    String recurrence = 'weekly',
    String? location,
    String? teacher,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    await _db.batch((b) {
      for (final wd in weekdays) {
        b.insert(
          _db.scheduleItems,
          ScheduleItemsCompanion.insert(
            uuid: genUuid(),
            courseName: courseName,
            type: Value(type),
            location: Value(location),
            teacher: Value(teacher),
            weekday: wd,
            recurrence: Value(recurrence),
            startTime: startTime,
            endTime: endTime,
            startDate: Value(startDate),
            endDate: Value(endDate),
            updatedAt: now,
          ),
        );
      }
    });
  }

  Future<int> remove(int id) =>
      (_db.update(_db.scheduleItems)..where((t) => t.id.equals(id))).write(
        ScheduleItemsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(appDatabaseProvider)),
);
