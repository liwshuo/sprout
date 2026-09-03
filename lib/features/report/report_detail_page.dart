import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/report_repository.dart';

/// 周报详情。editedText 优先展示，其次 aiText（技术方案 §6.2）。
class ReportDetailPage extends ConsumerWidget {
  const ReportDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(_reportProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('周报详情')),
      body: future.when(
        data: (r) {
          if (r == null) return const Center(child: Text('周报不存在'));
          final text = r.editedText ?? r.aiText ?? '（暂无正文）';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${DateUtil.formatDate(r.weekStart)} ~ ${DateUtil.formatDate(r.weekEnd.subtract(const Duration(days: 1)))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('日常 ${r.dailyCount}')),
                  Chip(label: Text('阅读 ${r.readingCount}')),
                  Chip(label: Text('阅读 ${r.readingMinutes} 分钟')),
                  Chip(label: Text('课外班 ${r.extraClassCount}')),
                  Chip(label: Text('活跃 ${r.activeDays} 天')),
                ],
              ),
              const Divider(height: 32),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

final _reportProvider =
    FutureProvider.autoDispose.family<WeeklyReport?, int>(
  (ref, id) => ref.watch(reportRepositoryProvider).findById(id),
);
