import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_util.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 孩子档案仓库。V1 单孩子；onboarding 建档、周报注入年龄/称呼时使用。
class ChildRepository {
  ChildRepository(this._db);

  final AppDatabase _db;

  /// 是否已建档（供 onboarding redirect 兜底判断）。
  Future<bool> hasChild() async {
    final row = await (_db.select(_db.child)
          ..where((c) => c.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<ChildData?> getFirst() => (_db.select(_db.child)
        ..where((c) => c.isDeleted.equals(false))
        ..limit(1))
      .getSingleOrNull();

  Stream<ChildData?> watchFirst() => (_db.select(_db.child)
        ..where((c) => c.isDeleted.equals(false))
        ..limit(1))
      .watchSingleOrNull();

  /// 建档：至少昵称必填，birthDate 可后补。
  Future<int> create({
    required String name,
    DateTime? birthDate,
    String? avatarPath,
  }) {
    return _db.into(_db.child).insert(
          ChildCompanion.insert(
            uuid: genUuid(),
            name: name,
            birthDate: Value(birthDate),
            avatarPath: Value(avatarPath),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<bool> update(ChildData child) =>
      _db.update(_db.child).replace(child.copyWith(updatedAt: DateTime.now()));
}

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => ChildRepository(ref.watch(appDatabaseProvider)),
);
