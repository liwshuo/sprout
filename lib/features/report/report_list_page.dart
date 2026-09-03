import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/report_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';

/// 周报列表（我的 → 成长周报）。
class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(_reportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('成长周报')),
      body: stream.when(
        data: (reports) => reports.isEmpty
            ? const EmptyPlaceholder(
                emoji: '🗓',
                message: '还没有周报',
                hint: '每周日 20:00 自动汇总这一周的成长，空周不生成',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                itemCount: reports.length,
                itemBuilder: (c, i) => _card(context, reports[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  Widget _card(BuildContext context, WeeklyReport r) {
    final end = r.weekEnd.subtract(const Duration(days: 1));
    final published = r.status == 'published';
    return SoftCard(
      radius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go('/mine/reports/${r.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconChip(emoji: '📊', color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('M月d日').format(r.weekStart)} - ${DateFormat('M月d日').format(end)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    const Text('那一周的成长足迹',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              StatusBadge(
                text: published ? '已发布' : '草稿',
                color: published ? AppColors.mint : AppColors.inkSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _mini('📝 记录 ${r.dailyCount}'),
              _mini('📖 阅读 ${r.readingCount}'),
              _mini('⏱ ${r.readingMinutes} 分'),
              _mini('🏫 课外 ${r.extraClassCount}'),
              _mini('🔥 活跃 ${r.activeDays} 天'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
      );
}

final _reportsProvider = StreamProvider.autoDispose<List<WeeklyReport>>(
  (ref) => ref.watch(reportRepositoryProvider).watchAll(),
);
