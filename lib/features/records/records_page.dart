import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';

/// 记录 Tab 根：日常记录列表（按 eventDate 倒序）+ 快速录入 + 计时器入口。
class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(_dailyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录'),
        actions: [
          IconButton(
            tooltip: '活动计时器',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => context.go('/records/timer'),
          ),
        ],
      ),
      body: stream.when(
        data: (records) => records.isEmpty
            ? const Center(child: Text('还没有记录，点右下角添加'))
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (c, i) {
                  final r = records[i];
                  return ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(r.title),
                    subtitle: Text(DateUtil.formatDate(r.eventDate)),
                    trailing: r.source == 'timer'
                        ? const Icon(Icons.timer, size: 16)
                        : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _quickAdd(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('快速记录'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '记点什么…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await ref.read(dailyRepositoryProvider).addFields(
            title: title,
            eventDate: DateTime.now(),
          );
    }
  }
}

final _dailyProvider = StreamProvider.autoDispose<List<DailyRecord>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchAll(),
);
