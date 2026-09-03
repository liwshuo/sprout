import 'dart:convert';

import '../../data/local/app_database.dart';
import '../theme/app_colors.dart';

/// DailyRecord 的展示派生：分类、emoji、标签列表、图片列表。
/// 口径：category = tags 首要分类标签（着色用），无独立"记录类型"维度。
extension DailyRecordX on DailyRecord {
  List<String> get tagList => _decodeList(tags);

  List<String> get imageList => _decodeList(imagePaths);

  /// 首要分类：优先 category 字段，否则取首个 tag，兜底"日常"。
  String get primaryCategory {
    if (category != null && category!.isNotEmpty) return category!;
    final t = tagList;
    if (t.isNotEmpty) return t.first;
    return '日常';
  }

  String get categoryEmoji => kCategoryEmoji[primaryCategory] ?? '🧩';

  String? get moodEmoji => mood == null ? null : AppColors.moodEmoji[mood!];
}

/// 分类 → emoji 图标。
const Map<String, String> kCategoryEmoji = {
  '日常': '🧩',
  '阅读': '📖',
  '课表': '🏫',
  '运动': '⚽',
  '才艺': '🎨',
  '出行': '🚗',
  '家务': '🧹',
  '情绪': '💗',
  '里程碑': '🏆',
  '其他': '✨',
};

List<String> _decodeList(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final v = jsonDecode(raw);
    if (v is List) return v.map((e) => e.toString()).toList();
  } catch (_) {}
  return const [];
}

String encodeStringList(List<String> list) =>
    list.isEmpty ? '' : jsonEncode(list);
