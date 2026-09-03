import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 阅读记录仓库。
class ReadingRepository {
  ReadingRepository(this._db);

  final AppDatabase _db;

  Future<List<BookRecord>> fetchAll() => _db.select(_db.bookRecords).get();

  Future<int> add(BookRecordsCompanion entry) =>
      _db.into(_db.bookRecords).insert(entry);

  Future<int> remove(int id) =>
      (_db.delete(_db.bookRecords)..where((t) => t.id.equals(id))).go();
}

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository(ref.watch(appDatabaseProvider));
});
