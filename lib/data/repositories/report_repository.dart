import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 周报仓库。
class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

  Future<List<WeeklyReport>> fetchAll() =>
      (_db.select(_db.weeklyReports)
            ..orderBy([(t) => OrderingTerm.desc(t.weekStart)]))
          .get();

  Future<int> add(WeeklyReportsCompanion entry) =>
      _db.into(_db.weeklyReports).insert(entry);

  Future<int> remove(int id) =>
      (_db.delete(_db.weeklyReports)..where((t) => t.id.equals(id))).go();
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(appDatabaseProvider));
});
