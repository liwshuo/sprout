/// 课表条目实体。
class ScheduleItem {
  final int? id;
  final String courseName;
  final String? location;
  final int weekday; // 1 = Monday ... 7 = Sunday
  final String startTime; // HH:mm
  final String endTime; // HH:mm

  const ScheduleItem({
    this.id,
    required this.courseName,
    this.location,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  ScheduleItem copyWith({
    int? id,
    String? courseName,
    String? location,
    int? weekday,
    String? startTime,
    String? endTime,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      location: location ?? this.location,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
