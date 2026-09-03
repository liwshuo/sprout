import 'package:flutter/material.dart';

/// 暖橙马卡龙设计令牌（对齐交互 Demo 的 :root CSS 变量）。
/// 全局唯一色彩来源，页面/组件不得内联硬编码色值。
class AppColors {
  AppColors._();

  // 背景 / 卡片
  static const Color bg = Color(0xFFFFF9F0);
  static const Color card = Color(0xFFFFFFFF);

  // 主色：暖橙
  static const Color primary = Color(0xFFFFB84C);
  static const Color primaryDeep = Color(0xFFF59E2E);
  static const Color primarySoft = Color(0xFFFFE7BF);

  // 辅助马卡龙色
  static const Color mint = Color(0xFF7ED9C3);
  static const Color mintSoft = Color(0xFFDBF5EE);
  static const Color sky = Color(0xFF8FC7F0);
  static const Color skySoft = Color(0xFFE1F0FB);
  static const Color pink = Color(0xFFFF9EB5);
  static const Color pinkSoft = Color(0xFFFFE3EA);
  static const Color lilac = Color(0xFFB7A5F0);
  static const Color lilacSoft = Color(0xFFEBE5FB);

  // 文字 / 描边
  static const Color ink = Color(0xFF4A4038); // 主文字（暖棕）
  static const Color inkSoft = Color(0xFF9A8F82); // 次要文字
  static const Color line = Color(0xFFF0E7D8); // 分隔/描边

  // 阴影
  static const Color shadow = Color(0x1FB48C46); // rgba(180,140,70,.12)

  /// 分类标签 → 主题色（日历圆点 / 时间轴图标底色）。
  /// 与需求文档的预置 tags 字典对齐；未知分类降级为暖橙。
  static const Map<String, Color> categoryColors = {
    '日常': primary,
    '阅读': mint,
    '课表': sky,
    '运动': pink,
    '才艺': lilac,
    '出行': sky,
    '家务': mint,
    '情绪': pink,
    '里程碑': primaryDeep,
    '其他': inkSoft,
  };

  static Color categoryColor(String? category) =>
      categoryColors[category] ?? primary;

  static Color categorySoft(String? category) {
    final c = categoryColor(category);
    return Color.alphaBlend(c.withValues(alpha: 0.18), Colors.white);
  }

  /// 心情 emoji 映射（记录 / 阅读打卡共用）。
  static const Map<String, String> moodEmoji = {
    'happy': '😄',
    'calm': '😊',
    'excited': '🤩',
    'tired': '😪',
    'upset': '😣',
  };
}
