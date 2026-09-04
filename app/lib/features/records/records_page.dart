import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/record_display.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';
import '../../shared/widgets/empty_placeholder.dart';
import 'quick_add_sheet.dart';
import 'record_tile.dart';

/// 记录 Tab 根：日常记录时间轴（按 eventDate 倒序）+ 分类筛选 + 快速录入 + 计时器入口。
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  String _filter = '全部';

  static const _filters = ['全部', '日常', '阅读', '运动', '才艺', '出行', '情绪', '里程碑'];

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(_dailyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChip(f),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: stream.when(
        data: (records) => _buildList(records),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('记一笔',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _filterChip(String f) {
    final active = _filter == f;
    final color = f == '全部' ? AppColors.primary : AppColors.categoryColor(f);
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? Color.alphaBlend(color.withValues(alpha: 0.2), Colors.white)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? color : AppColors.line, width: 2),
        ),
        child: Text(
          f,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? color : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<DailyRecord> all) {
    final records = _filter == '全部'
        ? all
        : all.where((r) => r.primaryCategory == _filter).toList();
    if (records.isEmpty) {
      return EmptyPlaceholder(
        emoji: '📝',
        message: _filter == '全部' ? '还没有记录' : '「$_filter」下还没有记录',
        hint: '点右下角「记一笔」，随手记录成长瞬间',
      );
    }
    // 按 eventDate 分组展示。
    final grouped = <String, List<DailyRecord>>{};
    for (final r in records) {
      grouped.putIfAbsent(DateUtil.formatDate(r.eventDate), () => []).add(r);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      itemCount: days.length,
      itemBuilder: (c, i) {
        final day = days[i];
        final items = grouped[day]!
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Text(
                _dayLabel(DateUtil.parseDate(day)),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ),
            for (final r in items) RecordTimelineTile(record: r),
          ],
        );
      },
    );
  }

  String _dayLabel(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(DateUtils.dateOnly(d)).inDays;
    if (diff == 0) return '今天 · ${DateFormat('M月d日').format(d)}';
    if (diff == 1) return '昨天 · ${DateFormat('M月d日').format(d)}';
    return DateFormat('M月d日 EEEE', 'zh').format(d);
  }
}

final _dailyProvider = StreamProvider.autoDispose<List<DailyRecord>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchAll(),
);
