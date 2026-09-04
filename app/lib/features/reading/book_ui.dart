import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 书籍展示相关的样式派生（封面渐变、状态色/文案）。
class BookUi {
  BookUi._();

  static const List<List<Color>> _gradients = [
    [Color(0xFFFFB84C), Color(0xFFF59E2E)],
    [Color(0xFF7ED9C3), Color(0xFF3AA88F)],
    [Color(0xFF8FC7F0), Color(0xFF3A7FB0)],
    [Color(0xFFB7A5F0), Color(0xFF6B5BB0)],
    [Color(0xFFFF9EB5), Color(0xFFD5607F)],
    [Color(0xFFFFD98A), Color(0xFFF59E2E)],
  ];

  static LinearGradient coverGradient(int id) {
    final pair = _gradients[id.abs() % _gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: pair,
    );
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'reading':
        return AppColors.primaryDeep;
      case 'done':
        return const Color(0xFF3AA88F);
      case 'want':
      default:
        return AppColors.sky;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'reading':
        return '● 在读';
      case 'done':
        return '✓ 已读完';
      case 'want':
      default:
        return '☆ 想读';
    }
  }
}
