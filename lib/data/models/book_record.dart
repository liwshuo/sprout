/// 书目 / 阅读记录实体。
class BookRecord {
  final int? id;
  final String bookName;
  final String? author;
  final int durationMinutes;
  final String? note;
  final DateTime readAt;

  const BookRecord({
    this.id,
    required this.bookName,
    this.author,
    this.durationMinutes = 0,
    this.note,
    required this.readAt,
  });

  BookRecord copyWith({
    int? id,
    String? bookName,
    String? author,
    int? durationMinutes,
    String? note,
    DateTime? readAt,
  }) {
    return BookRecord(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      author: author ?? this.author,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      note: note ?? this.note,
      readAt: readAt ?? this.readAt,
    );
  }
}
