import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/child_repository.dart';

/// 「我的」Tab 根：孩子档案入口 + 课表 / 周报 / 设置。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(_childProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          child.when(
            data: (c) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.child_care)),
              title: Text(c?.name ?? '未建档'),
              subtitle: const Text('孩子档案'),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('加载失败：$e'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('课表管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/mine/schedule'),
          ),
          ListTile(
            leading: const Icon(Icons.summarize),
            title: const Text('成长周报'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/mine/reports'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/mine/settings'),
          ),
        ],
      ),
    );
  }
}

final _childProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(childRepositoryProvider).watchFirst(),
);
