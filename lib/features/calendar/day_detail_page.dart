import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';

/// 当日详情：展示某天（eventDate）的日常记录聚合。
class DayDetailPage extends ConsumerWidget {
  const DayDetailPage({super.key, required this.date});

  /// 路由传入的 yyyy-MM-dd。
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateUtil.parseDate(date);
    final future = ref.watch(_dayRecordsProvider(day));
    return Scaffold(
      appBar: AppBar(title: Text(date)),
      body: future.when(
        data: (records) => records.isEmpty
            ? const Center(child: Text('这一天还没有记录'))
            : ListView(
                children: [
                  for (final r in records)
                    ListTile(
                      leading: const Icon(Icons.circle, size: 10),
                      title: Text(r.title),
                      subtitle: r.note == null ? null : Text(r.note!),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

final _dayRecordsProvider = FutureProvider.autoDispose
    .family<List<DailyRecord>, DateTime>(
  (ref, day) => ref.watch(dailyRepositoryProvider).fetchByDate(day),
);
