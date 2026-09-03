import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';

/// 日历主视图（日历 Tab 根）。按 eventDate 聚合展示有记录的日期，点击下钻当日详情。
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyStream = ref.watch(_recentDailyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('日历 · 成长足迹')),
      body: dailyStream.when(
        data: (records) => _buildList(context, records),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<DailyRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('本月还没有记录，去「记录」Tab 添加吧'));
    }
    // 按 eventDate 分组
    final grouped = <String, List<DailyRecord>>{};
    for (final r in records) {
      final key = DateUtil.formatDate(r.eventDate);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (c, i) {
        final day = days[i];
        final items = grouped[day]!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.event_note),
            title: Text(day),
            subtitle: Text('${items.length} 条记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/calendar/day/$day'),
          ),
        );
      },
    );
  }
}

/// 最近一个月的日常记录（按 eventDate 区间聚合，避免全表扫）。
final _recentDailyProvider = StreamProvider.autoDispose<List<DailyRecord>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchAll(),
);
