import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 预置分类标签字典（记录分类统一走 tags；首个选中项作为 category 着色）。
const List<String> kPresetTags = [
  '运动',
  '才艺',
  '出行',
  '家务',
  '情绪',
  '阅读',
  '里程碑',
  '其他',
];

/// 心情选项（key 落库，emoji 展示）。
const List<({String key, String emoji, String label})> kMoods = [
  (key: 'happy', emoji: '😄', label: '开心'),
  (key: 'calm', emoji: '😊', label: '平静'),
  (key: 'excited', emoji: '🤩', label: '兴奋'),
  (key: 'tired', emoji: '😪', label: '疲惫'),
  (key: 'upset', emoji: '😣', label: '闹脾气'),
];

/// 心情选择器：一排圆形 emoji，单选。
class MoodPicker extends StatelessWidget {
  const MoodPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        for (final m in kMoods)
          GestureDetector(
            onTap: () => onChanged(value == m.key ? null : m.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value == m.key ? AppColors.primarySoft : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value == m.key ? AppColors.primary : AppColors.line,
                  width: 2,
                ),
              ),
              child: Text(m.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
      ],
    );
  }
}

/// 多选标签 chips（记录分类统一由 tags 承载，无独立类型维度）。
class TagSelector extends StatelessWidget {
  const TagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.tags = kPresetTags,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in tags)
          _chip(
            label: t,
            active: selected.contains(t),
            onTap: () {
              final next = Set<String>.from(selected);
              if (!next.remove(t)) next.add(t);
              onChanged(next);
            },
          ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = AppColors.categoryColor(label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Color.alphaBlend(color.withValues(alpha: 0.2), Colors.white)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : AppColors.line,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? color : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// 时长快捷选择（15/30/45 分钟 + 自定义），用于阅读打卡 / 计时补录。
class DurationQuickPicker extends StatelessWidget {
  const DurationQuickPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.presets = const [15, 30, 45],
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final List<int> presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in presets)
          _pill('$p 分钟', value == p, () => onChanged(value == p ? null : p)),
        _pill(
          value != null && !presets.contains(value) ? '$value 分钟' : '自定义',
          value != null && !presets.contains(value),
          () async {
            final v = await _askCustom(context);
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _pill(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.mintSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.mint : AppColors.line,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF3AA88F) : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Future<int?> _askCustom(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('自定义时长（分钟）'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '例如 25'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              Navigator.pop(c, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
