import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/reading_repository.dart';
import '../../domain/bookshelf/book_shelf_service.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';
import 'book_ui.dart';
import 'reading_checkin_sheet.dart';

/// 书籍详情：封面 hero + 进度 + 打卡历史 + 追加打卡（触发 status 自动跃迁）。
class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(_shelfProvider);
    final logs = ref.watch(_logsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('书籍详情'),
        actions: [
          shelf.maybeWhen(
            data: (items) {
              final item = _find(items);
              if (item == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (v) =>
                    ref.read(readingRepositoryProvider).setStatusManually(id, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'want', child: Text('标记想读')),
                  PopupMenuItem(value: 'reading', child: Text('标记在读')),
                  PopupMenuItem(value: 'done', child: Text('标记已读完')),
                ],
                icon: const Icon(Icons.more_horiz),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: shelf.when(
        data: (items) {
          final item = _find(items);
          if (item == null) return const EmptyPlaceholder(message: '书籍不存在');
          return logs.when(
            data: (list) => _body(context, ref, item, list),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: shelf.maybeWhen(
        data: (items) {
          final item = _find(items);
          if (item == null) return null;
          return FloatingActionButton.extended(
            onPressed: () =>
                ReadingCheckInSheet.show(context, book: item.book),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('打卡',
                style: TextStyle(fontWeight: FontWeight.w800)),
          );
        },
        orElse: () => null,
      ),
    );
  }

  BookShelfItem? _find(List<BookShelfItem> items) {
    for (final it in items) {
      if (it.book.id == id) return it;
    }
    return null;
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    BookShelfItem item,
    List<ReadingLog> logs,
  ) {
    final book = item.book;
    final progress = item.progress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      children: [
        SoftCard(
          radius: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 84,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: BookUi.coverGradient(book.id),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: const Text('📕', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(book.author ?? '未知作者',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.inkSoft)),
                    const SizedBox(height: 10),
                    StatusBadge(
                        text: BookUi.statusLabel(book.status),
                        color: BookUi.statusColor(book.status)),
                    const SizedBox(height: 12),
                    _progressLine(item, progress),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _statsRow(item),
        const SizedBox(height: 18),
        SectionHeader(
          title: '打卡历史',
          emoji: '📖',
          trailing: Text('${logs.length} 次',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft)),
        ),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: EmptyPlaceholder(
              emoji: '✏️',
              message: '还没有打卡记录',
              hint: '点下方「打卡」记录今天的亲子共读',
            ),
          )
        else
          for (final l in logs) _logTile(l),
      ],
    );
  }

  Widget _progressLine(BookShelfItem item, double? progress) {
    if (progress == null) {
      return Text(
        item.logCount > 0 ? '已打卡 ${item.logCount} 次' : '还没开始，加油鸭',
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('进度 ${(progress * 100).round()}%',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.line,
            valueColor:
                AlwaysStoppedAnimation(BookUi.statusColor(item.book.status)),
          ),
        ),
      ],
    );
  }

  Widget _statsRow(BookShelfItem item) {
    return Row(
      children: [
        _stat('${item.logCount}', '打卡次数', AppColors.primary),
        const SizedBox(width: 10),
        _stat('${item.totalMinutes}', '阅读分钟', AppColors.mint),
        const SizedBox(width: 10),
        _stat(item.maxPage != null ? '${item.maxPage}' : '—', '读到页', AppColors.sky),
      ],
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: SoftCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _logTile(ReadingLog l) {
    final mood = l.mood == null ? null : AppColors.moodEmoji[l.mood!];
    final title = l.pageTo != null
        ? '读到第 ${l.pageTo} 页'
        : (l.chapter ?? '完成一次共读');
    return SoftCard(
      radius: 16,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconChip(emoji: '📖', color: AppColors.mint, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                    ),
                    if (mood != null)
                      Text(mood, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                if (l.note != null && l.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(l.note!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          height: 1.4)),
                ],
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('M月d日', 'zh').format(l.readDate)} · ${l.durationMinutes} 分钟',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _shelfProvider = StreamProvider.autoDispose<List<BookShelfItem>>(
  (ref) => ref.watch(bookShelfServiceProvider).watchShelf(),
);

final _logsProvider =
    StreamProvider.autoDispose.family<List<ReadingLog>, int>(
  (ref, bookId) => ref.watch(readingRepositoryProvider).watchLogs(bookId),
);
