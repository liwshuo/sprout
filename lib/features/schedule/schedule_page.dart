import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/schedule_repository.dart';

const _weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

/// 课表管理（我的 → 课表）。按 weekday 分组展示。
class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(_scheduleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('课表管理')),
      body: stream.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('还没有课程'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (c, i) {
                  final it = items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(_weekdayNames[
                          (it.weekday - 1).clamp(0, 6)]),
                    ),
                    title: Text(it.courseName),
                    subtitle: Text(
                        '${it.startTime}-${it.endTime} · ${it.type == 'extra' ? '课外班' : '学校'}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

final _scheduleProvider = StreamProvider.autoDispose<List<ScheduleItem>>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchAll(),
);
