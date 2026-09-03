import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_util.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 套书仓库。已读完册数不冗余存储，聚合在 BookShelfService.seriesProgress。
/// 注意：series 只被 reading 单向依赖，严禁反向 watch readingRepository（规避循环依赖）。
class SeriesRepository {
  SeriesRepository(this._db);

  final AppDatabase _db;

  Stream<List<SeriesData>> watchAll() => (_db.select(_db.series)
        ..where((s) => s.isDeleted.equals(false))
        ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
      .watch();

  Future<int> create({required String name, int totalVolumes = 0}) {
    return _db.into(_db.series).insert(
          SeriesCompanion.insert(
            uuid: genUuid(),
            name: name,
            totalVolumes: Value(totalVolumes),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<int> remove(int id) {
    // 软删；物理层 Books.seriesId 外键 setNull 兜底让分册降级为独立书。
    return (_db.update(_db.series)..where((s) => s.id.equals(id))).write(
      SeriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final seriesRepositoryProvider = Provider<SeriesRepository>(
  (ref) => SeriesRepository(ref.watch(appDatabaseProvider)),
);
