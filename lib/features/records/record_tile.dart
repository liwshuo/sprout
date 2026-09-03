import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/record_display.dart';
import '../../data/local/app_database.dart';
import '../../shared/widgets/app_widgets.dart';

/// 时间轴记录卡片（日历当日视图 / 记录列表共用）。
class RecordTimelineTile extends StatelessWidget {
  const RecordTimelineTile({
    super.key,
    required this.record,
    this.onTap,
    this.showTime = true,
  });

  final DailyRecord record;
  final VoidCallback? onTap;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final category = record.primaryCategory;
    final color = AppColors.categoryColor(category);
    final tags = record.tagList;
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(emoji: record.categoryEmoji, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (record.moodEmoji != null)
                      Text(record.moodEmoji!,
                          style: const TextStyle(fontSize: 16)),
                  ],
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
                if (record.imageList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _thumbnails(record.imageList),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showTime)
                      Text(
                        DateFormat('HH:mm').format(record.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    if (record.durationMinutes != null) ...[
                      const SizedBox(width: 8),
                      _mini('${record.durationMinutes} 分钟'),
                    ],
                    const Spacer(),
                    if (record.source == 'timer') _mini('⏱ 计时'),
                    if (record.source == 'voice') _mini('🎤 语音'),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.categorySoft(t),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.categoryColor(t),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 记录配图缩略图：最多展示 3 张，超出以「+N」蒙层提示。
  Widget _thumbnails(List<String> images) {
    const maxShow = 3;
    final show = images.take(maxShow).toList();
    final extra = images.length - show.length;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (int i = 0; i < show.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image(
                    image: _imageProvider(show[i]),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.line,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 20, color: AppColors.inkSoft),
                    ),
                  ),
                  if (i == show.length - 1 && extra > 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.42),
                        alignment: Alignment.center,
                        child: Text(
                          '+$extra',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  Widget _mini(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
      );
}
