/// 周报实体。
class WeeklyReport {
  final int? id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String summary;
  final int dailyCount;
  final int readingCount;
  final int readingMinutes;
  final DateTime generatedAt;

  const WeeklyReport({
    this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.summary,
    this.dailyCount = 0,
    this.readingCount = 0,
    this.readingMinutes = 0,
    required this.generatedAt,
  });

  WeeklyReport copyWith({
    int? id,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? summary,
    int? dailyCount,
    int? readingCount,
    int? readingMinutes,
    DateTime? generatedAt,
  }) {
    return WeeklyReport(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      summary: summary ?? this.summary,
      dailyCount: dailyCount ?? this.dailyCount,
      readingCount: readingCount ?? this.readingCount,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
