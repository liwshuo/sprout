import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/report_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';

/// 周报详情：5 项概览 + 正文（editedText 优先，其次 aiText，再次本地模板 summary）。
class ReportDetailPage extends ConsumerWidget {
  const ReportDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(_reportProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('周报详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: '分享',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享长图为 P1 能力，敬请期待～'))),
          ),
        ],
      ),
      body: future.when(
        data: (r) {
          if (r == null) return const EmptyPlaceholder(message: '周报不存在');
          return _body(context, r);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  Widget _body(BuildContext context, WeeklyReport r) {
    final end = r.weekEnd.subtract(const Duration(days: 1));
    final text = (r.editedText?.isNotEmpty == true)
        ? r.editedText!
        : (r.aiText?.isNotEmpty == true)
            ? r.aiText!
            : '这一周还没有正文，先看看上面的概览吧 🌱';
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // 顶部周次卡
        SoftCard(
          radius: 22,
          color: AppColors.primarySoft,
          child: Row(
            children: [
              const Text('🌈', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('yyyy年M月d日').format(r.weekStart)} - ${DateFormat('M月d日').format(end)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    const Text('这一周的成长小结',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 5 项概览
        const SectionHeader(title: '本周概览', emoji: '📊'),
        _overviewGrid(r),
        const SizedBox(height: 18),
        // 正文
        const SectionHeader(title: '成长故事', emoji: '📖'),
        SoftCard(
          radius: 20,
          child: Text(text,
              style: const TextStyle(
                  fontSize: 15, height: 1.7, color: AppColors.ink)),
        ),
      ],
    );
  }

  Widget _overviewGrid(WeeklyReport r) {
    final items = [
      ('📝', '${r.dailyCount}', '记录条数', AppColors.primary),
      ('📖', '${r.readingCount}', '阅读本数', AppColors.mint),
      ('⏱', '${r.readingMinutes}', '阅读时长(分)', AppColors.sky),
      ('🏫', '${r.extraClassCount}', '课外班次数', AppColors.lilac),
      ('🔥', '${r.activeDays}', '活跃天数', AppColors.pink),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final it in items)
          SoftCard(
            radius: 16,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(it.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(it.$2,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: it.$4)),
                const SizedBox(height: 2),
                Text(it.$3,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft)),
              ],
            ),
          ),
      ],
    );
  }
}

final _reportProvider =
    FutureProvider.autoDispose.family<WeeklyReport?, int>(
  (ref, id) => ref.watch(reportRepositoryProvider).findById(id),
);
