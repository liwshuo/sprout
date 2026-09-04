import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 周报仓库。周报是生成时快照，冗余统计字段避免重复计算。
class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeeklyReport>> watchAll() => (_db.select(_db.weeklyReports)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.weekStart)]))
      .watch();

  Future<WeeklyReport?> findByWeekStart(DateTime weekStart) =>
      (_db.select(_db.weeklyReports)
            ..where((t) =>
                t.weekStart.equals(weekStart) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<WeeklyReport?> findById(int id) => (_db.select(_db.weeklyReports)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  Future<int> add(WeeklyReportsCompanion entry) =>
      _db.into(_db.weeklyReports).insert(entry);

  Future<bool> update(WeeklyReport entry) =>
      _db.update(_db.weeklyReports).replace(
            entry.copyWith(updatedAt: DateTime.now()),
          );

  Future<int> remove(int id) =>
      (_db.update(_db.weeklyReports)..where((t) => t.id.equals(id))).write(
        WeeklyReportsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(appDatabaseProvider)),
);
