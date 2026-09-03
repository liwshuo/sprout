import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 日常事项表。
class DailyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 阅读记录表。
class BookRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookName => text()();
  TextColumn get author => text().nullable()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get readAt => dateTime()();
}

/// 课表表。
class ScheduleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text()();
  TextColumn get location => text().nullable()();
  IntColumn get weekday => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
}

/// 周报表。
class WeeklyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStart => dateTime()();
  DateTimeColumn get weekEnd => dateTime()();
  TextColumn get summary => text()();
  IntColumn get dailyCount => integer().withDefault(const Constant(0))();
  IntColumn get readingCount => integer().withDefault(const Constant(0))();
  IntColumn get readingMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get generatedAt => dateTime()();
}

@DriftDatabase(
  tables: [DailyRecords, BookRecords, ScheduleItems, WeeklyReports],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sprout.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
