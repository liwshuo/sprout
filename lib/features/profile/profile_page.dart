import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/child_repository.dart';
import '../../shared/widgets/app_widgets.dart';

/// 「我的」Tab 根：孩子档案卡 + 课表 / 周报 / 设置入口。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(_childProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          child.when(
            data: (c) => _childCard(context, c),
            loading: () => const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('加载失败：$e'),
          ),
          const SizedBox(height: 20),
          _menuCard(context),
        ],
      ),
    );
  }

  Widget _childCard(BuildContext context, ChildData? c) {
    final age = c?.birthDate == null ? null : _ageText(c!.birthDate!);
    return SoftCard(
      radius: 24,
      color: AppColors.primarySoft,
      onTap: () => context.go('/onboarding'),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text('🐣', style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c?.name ?? '还没有档案',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  c == null
                      ? '点这里给宝贝建个档案吧'
                      : (age ?? '生日待补充'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primaryDeep),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context) {
    final items = [
      ('🏫', '课表管理', '幼儿园 / 课外班安排', AppColors.sky, '/mine/schedule'),
      ('📊', '成长周报', '每周自动汇总', AppColors.primary, '/mine/reports'),
      ('⚙️', '设置', '通知 / 周报时间 / 数据', AppColors.lilac, '/mine/settings'),
    ];
    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go(items[i].$5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconChip(emoji: items[i].$1, color: items[i].$4, size: 42),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].$2,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(items[i].$3,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 64, endIndent: 8),
          ],
        ],
      ),
    );
  }

  String _ageText(DateTime birth) {
    final now = DateTime.now();
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) months -= 1;
    if (months < 0) months = 0;
    final y = months ~/ 12;
    final m = months % 12;
    final ymd = DateFormat('yyyy年M月d日').format(birth);
    if (y == 0) return '$m 个月 · $ymd 出生';
    return '$y 岁 $m 个月 · $ymd 出生';
  }
}

final _childProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(childRepositoryProvider).watchFirst(),
);
