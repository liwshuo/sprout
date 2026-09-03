import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/report_repository.dart';

/// 周报列表（我的 → 周报）。
class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(_reportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('成长周报')),
      body: stream.when(
        data: (reports) => reports.isEmpty
            ? const Center(child: Text('还没有周报，周日 20:00 自动生成'))
            : ListView.builder(
                itemCount: reports.length,
                itemBuilder: (c, i) {
                  final r = reports[i];
                  return ListTile(
                    leading: const Icon(Icons.summarize),
                    title: Text(
                        '${DateUtil.formatDate(r.weekStart)} 那一周'),
                    subtitle: Text(
                        '阅读 ${r.readingCount} 次 · 活跃 ${r.activeDays} 天 · ${r.status == 'published' ? '已发布' : '草稿'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/mine/reports/${r.id}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

final _reportsProvider = StreamProvider.autoDispose<List<WeeklyReport>>(
  (ref) => ref.watch(reportRepositoryProvider).watchAll(),
);
