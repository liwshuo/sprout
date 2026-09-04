import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// =============================================================================
// 阅读域：Series（套书）1—N Books（书单）1—N ReadingLogs（打卡）
// 单一真相源：Books 不存"当前已读页/章"，进度由 ReadingLogs 聚合派生（技术方案 §5.7）
// =============================================================================

/// 套书主表。已读完册数不冗余存储，实时聚合 count(Books where seriesId=X and status='done')。
@DataClassName('SeriesData')
class Series extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get name => text()();
  IntColumn get totalVolumes => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// 书单主表。status: want / reading / done，自动跃迁在 ReadingRepository.addLog 写侧判定。
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get cover => text().nullable()();
  TextColumn get isbn => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('want'))(); // want / reading / done
  IntColumn get totalPages => integer().nullable()();
  IntColumn get totalChapters => integer().nullable()();
  // 套书归属：删套书主记录时分册降级为独立书（setNull），不误删书。
  IntColumn get seriesId => integer()
      .nullable()
      .references(Series, #id, onDelete: KeyAction.setNull)();
  IntColumn get seriesIndex => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// 阅读打卡明细。进度口径：已读页 = max(pageTo)、已读章 = max(chapterIndex)。
class ReadingLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  // 删书自动清打卡（cascade），物理级联仅作兜底防悬空。
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get readDate => dateTime()();
  TextColumn get chapter => text().nullable()(); // 展示串
  IntColumn get chapterIndex => integer().nullable()(); // 聚合排序用
  IntColumn get pageFrom => integer().nullable()();
  IntColumn get pageTo => integer().nullable()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get mood => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get source =>
      text().withDefault(const Constant('manual'))(); // manual / voice / timer
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

// =============================================================================
// 日常 / 课表 / 周报 / 孩子档案
// =============================================================================

/// 日常事项表。eventDate 独立于 createdAt，日历/周报按 eventDate 聚合（支持补填过去某天）。
class DailyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON 数组
  TextColumn get imagePaths => text().nullable()(); // JSON 多图
  TextColumn get category =>
      text().nullable()(); // 首要分类标签（取自 tags，用于日历/周报着色；无独立"记录类型"维度）
  TextColumn get mood => text().nullable()();
  TextColumn get source =>
      text().withDefault(const Constant('manual'))(); // manual / voice / timer
  DateTimeColumn get eventDate => dateTime()(); // 事件发生日期
  IntColumn get durationMinutes => integer().nullable()(); // 计时通用活动时长
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// 课表表。每条仅存单个 weekday；"多选周几"落库时拆成多行。
class ScheduleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get courseName => text()();
  TextColumn get type =>
      text().withDefault(const Constant('school'))(); // school / extra
  TextColumn get location => text().nullable()();
  TextColumn get teacher => text().nullable()();
  IntColumn get weekday => integer()(); // 1=Mon ... 7=Sun
  TextColumn get recurrence =>
      text().withDefault(const Constant('weekly'))(); // weekly / biweekly / monthly / once（once 为单次课，仅在 startDate 当天生成一次实例）
  TextColumn get startTime => text()(); // HH:mm
  TextColumn get endTime => text()(); // HH:mm
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// 周报表。快照冗余统计字段；aiText 保留 AI 原文，editedText 存家长编辑版。
class WeeklyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  DateTimeColumn get weekStart => dateTime()();
  DateTimeColumn get weekEnd => dateTime()();
  TextColumn get summary => text()(); // 结构化 JSON
  TextColumn get aiText => text().nullable()();
  TextColumn get editedText => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))(); // draft / published
  IntColumn get dailyCount => integer().withDefault(const Constant(0))();
  IntColumn get readingCount => integer().withDefault(const Constant(0))();
  IntColumn get readingMinutes => integer().withDefault(const Constant(0))();
  IntColumn get extraClassCount => integer().withDefault(const Constant(0))();
  IntColumn get activeDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// 孩子档案表。V1 单孩子只存一行；birthDate 缺失时周报年龄/称呼降级为"孩子/宝贝"。
@DataClassName('ChildData')
class Child extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Series,
    Books,
    ReadingLogs,
    DailyRecords,
    ScheduleItems,
    WeeklyReports,
    Child,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 供测试注入内存/自定义连接。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // drift/SQLite 默认 PRAGMA foreign_keys = OFF，必须每次打开连接显式开启，
          // 否则 Books.seriesId / ReadingLogs.bookId 外键形同虚设（含后台 isolate）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sprout.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
