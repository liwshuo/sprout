import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';
import '../../shared/widgets/empty_placeholder.dart';
import '../records/quick_add_sheet.dart';
import '../records/record_tile.dart';

/// 当日详情：展示某天（eventDate）的日常记录聚合，可直接补记当天。
class DayDetailPage extends ConsumerWidget {
  const DayDetailPage({super.key, required this.date});

  /// 路由传入的 yyyy-MM-dd。
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateUtil.parseDate(date);
    final future = ref.watch(_dayRecordsProvider(day));
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('M月d日 EEEE', 'zh').format(day))),
      body: future.when(
        data: (records) {
          if (records.isEmpty) {
            return const EmptyPlaceholder(
              emoji: '🌤',
              message: '这一天还没有记录',
              hint: '点右下角补记这天的小美好',
            );
          }
          final sorted = [...records]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            children: [for (final r in sorted) RecordTimelineTile(record: r)],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddSheet.show(context, initialDate: day),
        icon: const Icon(Icons.add),
        label: const Text('补记这天',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

final _dayRecordsProvider =
    FutureProvider.autoDispose.family<List<DailyRecord>, DateTime>(
  (ref, day) => ref.watch(dailyRepositoryProvider).fetchByDate(day),
);
