/// 日常事项记录实体。
class DailyRecord {
  final int? id;
  final String title;
  final String? note;
  final String? imagePath;
  final DateTime createdAt;

  const DailyRecord({
    this.id,
    required this.title,
    this.note,
    this.imagePath,
    required this.createdAt,
  });

  DailyRecord copyWith({
    int? id,
    String? title,
    String? note,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
