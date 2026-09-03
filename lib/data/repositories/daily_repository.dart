import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 日常事项仓库。
class DailyRepository {
  DailyRepository(this._db);

  final AppDatabase _db;

  Future<List<DailyRecord>> fetchAll() => _db.select(_db.dailyRecords).get();

  Future<int> add(DailyRecordsCompanion entry) =>
      _db.into(_db.dailyRecords).insert(entry);

  Future<bool> update(DailyRecord entry) =>
      _db.update(_db.dailyRecords).replace(entry);

  Future<int> remove(int id) =>
      (_db.delete(_db.dailyRecords)..where((t) => t.id.equals(id))).go();
}

final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  return DailyRepository(ref.watch(appDatabaseProvider));
});
