import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';

/// 单本书的书架视图（进度全部由 ReadingLogs 聚合派生，Books 不存当前进度）。
class BookShelfItem {
  final Book book;
  final int? maxPage; // max(pageTo)
  final int? maxChapter; // max(chapterIndex)
  final int logCount; // 打卡次数
  final int totalMinutes; // sum(durationMinutes)
  final DateTime? lastReadAt;

  const BookShelfItem({
    required this.book,
    this.maxPage,
    this.maxChapter,
    required this.logCount,
    required this.totalMinutes,
    this.lastReadAt,
  });

  /// 进度三档降级：页 > 章 > 打卡次数。两者皆无返回 null → UI 展示打卡次数图标。
  double? get progress {
    if (book.totalPages != null && book.totalPages! > 0 && maxPage != null) {
      return (maxPage! / book.totalPages!).clamp(0.0, 1.0);
    }
    if (book.totalChapters != null &&
        book.totalChapters! > 0 &&
        maxChapter != null) {
      return (maxChapter! / book.totalChapters!).clamp(0.0, 1.0);
    }
    return null;
  }
}

/// 书架/套书只读聚合服务：只依赖 AppDatabase 做联表查询，不反向持有任何 Repository，
/// 从源头规避 reading↔series 循环依赖（技术方案 §3.4）。
class BookShelfService {
  BookShelfService(this._db);

  final AppDatabase _db;

  /// 一次 JOIN Books ⨝ ReadingLogs + GROUP BY，避免每本书各跑一次聚合（防 N+1）。
  Stream<List<BookShelfItem>> watchShelf() {
    final logs = _db.readingLogs;
    final books = _db.books;
    final maxPage = logs.pageTo.max();
    final maxChap = logs.chapterIndex.max();
    final cnt = logs.id.count();
    final mins = logs.durationMinutes.sum();
    final last = logs.readDate.max();

    final query = _db.select(books).join([
      leftOuterJoin(
        logs,
        logs.bookId.equalsExp(books.id) & logs.isDeleted.equals(false),
      ),
    ])
      // 聚合表达式必须显式加入 SELECT 列集，否则 r.read(agg) 会抛
      // "This result set does not have a column for that expression."
      ..addColumns([maxPage, maxChap, cnt, mins, last])
      ..where(books.isDeleted.equals(false))
      ..groupBy([books.id])
      ..orderBy([OrderingTerm.desc(last)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (r) => BookShelfItem(
                  book: r.readTable(books),
                  maxPage: r.read(maxPage),
                  maxChapter: r.read(maxChap),
                  logCount: r.read(cnt) ?? 0,
                  totalMinutes: r.read(mins) ?? 0,
                  lastReadAt: r.read(last),
                ),
              )
              .toList(),
        );
  }

  /// 套书进度 = 已读完分册数 / 总册数（实时聚合，不冗余存字段、不增量写）。
  Future<double> seriesProgress(int seriesId) async {
    final series = await (_db.select(_db.series)
          ..where((s) => s.id.equals(seriesId)))
        .getSingle();
    final done = _db.books.id.count();
    final q = _db.selectOnly(_db.books)
      ..addColumns([done])
      ..where(
        _db.books.seriesId.equals(seriesId) &
            _db.books.status.equals('done') &
            _db.books.isDeleted.equals(false),
      );
    final finished = await q.map((r) => r.read(done) ?? 0).getSingle();
    return series.totalVolumes == 0
        ? 0
        : (finished / series.totalVolumes).clamp(0.0, 1.0);
  }
}

final bookShelfServiceProvider = Provider<BookShelfService>(
  (ref) => BookShelfService(ref.watch(appDatabaseProvider)),
);
