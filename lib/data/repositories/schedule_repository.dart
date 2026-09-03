import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 课表仓库。
class ScheduleRepository {
  ScheduleRepository(this._db);

  final AppDatabase _db;

  Future<List<ScheduleItem>> fetchAll() =>
      _db.select(_db.scheduleItems).get();

  Future<List<ScheduleItem>> fetchByWeekday(int weekday) =>
      (_db.select(_db.scheduleItems)..where((t) => t.weekday.equals(weekday)))
          .get();

  Future<int> add(ScheduleItemsCompanion entry) =>
      _db.into(_db.scheduleItems).insert(entry);

  Future<int> remove(int id) =>
      (_db.delete(_db.scheduleItems)..where((t) => t.id.equals(id))).go();
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(appDatabaseProvider));
});
