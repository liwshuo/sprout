import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_util.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

/// 阅读仓库：管理 Books（书单）+ ReadingLogs（打卡）。
/// 进度单一真相源：所有入口只追加 ReadingLog，绝不各自回写进度字段。
class ReadingRepository {
  ReadingRepository(this._db);

  final AppDatabase _db;

  // ---- Books ----

  Stream<List<Book>> watchBooks({String? status}) {
    final q = _db.select(_db.books)..where((b) => b.isDeleted.equals(false));
    if (status != null) {
      q.where((b) => b.status.equals(status));
    }
    q.orderBy([(b) => OrderingTerm.desc(b.updatedAt)]);
    return q.watch();
  }

  Future<Book?> findByIsbn(String isbn) => (_db.select(_db.books)
        ..where((b) => b.isbn.equals(isbn) & b.isDeleted.equals(false)))
      .getSingleOrNull();

  Future<int> createBook({
    required String title,
    String? author,
    String? cover,
    String? isbn,
    int? totalPages,
    int? totalChapters,
    int? seriesId,
    int? seriesIndex,
  }) {
    return _db.into(_db.books).insert(
          BooksCompanion.insert(
            uuid: genUuid(),
            title: title,
            author: Value(author),
            cover: Value(cover),
            isbn: Value(isbn),
            status: const Value('want'),
            totalPages: Value(totalPages),
            totalChapters: Value(totalChapters),
            seriesId: Value(seriesId),
            seriesIndex: Value(seriesIndex),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// 家长手动改状态（优先级最高，直写，不走 addLog 的自动跃迁）。
  Future<void> setStatusManually(int bookId, String status) {
    return (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> removeBook(int bookId) {
    // 软删为主；物理级联（ReadingLogs cascade）作兜底防悬空。
    return (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---- ReadingLogs ----

  Stream<List<ReadingLog>> watchLogs(int bookId) => (_db.select(_db.readingLogs)
        ..where((l) => l.bookId.equals(bookId) & l.isDeleted.equals(false))
        ..orderBy([(l) => OrderingTerm.desc(l.readDate)]))
      .watch();

  /// 追加打卡 + 处理 status 自动跃迁（唯一写进度状态的入口）。
  Future<void> addLog(
    ReadingLogsCompanion log, {
    bool markFinished = false,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.readingLogs).insert(log);
      final bookId = log.bookId.value;
      final book = await (_db.select(_db.books)
            ..where((b) => b.id.equals(bookId)))
          .getSingle();
      String? next;
      if (markFinished) {
        next = 'done'; // 勾选读完
      } else if (book.status == 'want') {
        next = 'reading'; // 首次打卡：想读→在读
      }
      // 手动置 done 的书不因打卡退回 reading（手动优先由 setStatusManually 直写）。
      if (next != null && next != book.status) {
        await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
          BooksCompanion(
            status: Value(next),
            // 同步预留：状态变更必刷 updatedAt，否则 V2 同步会漏这条。
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// 便捷方法：直接用字段追加打卡（自动补 uuid / updatedAt / source）。
  Future<void> addLogFields({
    required int bookId,
    required DateTime readDate,
    String? chapter,
    int? chapterIndex,
    int? pageFrom,
    int? pageTo,
    int durationMinutes = 0,
    String? mood,
    String? note,
    String source = 'manual',
    bool markFinished = false,
  }) {
    return addLog(
      ReadingLogsCompanion.insert(
        uuid: genUuid(),
        bookId: bookId,
        readDate: readDate,
        chapter: Value(chapter),
        chapterIndex: Value(chapterIndex),
        pageFrom: Value(pageFrom),
        pageTo: Value(pageTo),
        durationMinutes: Value(durationMinutes),
        mood: Value(mood),
        note: Value(note),
        source: Value(source),
        updatedAt: DateTime.now(),
      ),
      markFinished: markFinished,
    );
  }
}

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => ReadingRepository(ref.watch(appDatabaseProvider)),
);
