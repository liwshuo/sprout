import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_util.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/reading_repository.dart';

/// 书籍详情：展示打卡记录 + 追加打卡（触发 status 自动跃迁）。
class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_logsProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('书籍详情')),
      body: logs.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('还没有打卡记录'))
            : ListView(
                children: [
                  for (final l in list)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(l.pageTo != null
                          ? '读到第 ${l.pageTo} 页'
                          : (l.chapter ?? '打卡')),
                      subtitle: Text(
                          '${DateUtil.formatDate(l.readDate)} · ${l.durationMinutes} 分钟'),
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('打卡'),
        onPressed: () => _checkIn(context, ref),
      ),
    );
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    // 只追加一条 ReadingLog，不回写进度字段；首次打卡自动 want→reading。
    await ref.read(readingRepositoryProvider).addLogFields(
          bookId: id,
          readDate: DateTime.now(),
          durationMinutes: 15,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已打卡')));
    }
  }
}

final _logsProvider = StreamProvider.autoDispose
    .family<List<ReadingLog>, int>(
  (ref, bookId) => ref.watch(readingRepositoryProvider).watchLogs(bookId),
);
