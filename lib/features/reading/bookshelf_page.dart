import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/reading_repository.dart';
import '../../domain/bookshelf/book_shelf_service.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';
import 'book_ui.dart';

/// 书架 Tab 根：三分区（在读 / 想读 / 已读）+ 进度环。
/// 进度全部由 BookShelfService 聚合派生，页面不直接读 Books 进度字段。
class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage> {
  int _seg = 0; // 0 在读 / 1 想读 / 2 已读
  static const _statuses = ['reading', 'want', 'done'];

  @override
  Widget build(BuildContext context) {
    final shelf = ref.watch(_shelfProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('书架 · 阅读足迹')),
      body: shelf.when(
        data: (items) {
          final status = _statuses[_seg];
          final list =
              items.where((e) => e.book.status == status).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: SegmentedTabs(
                  segments: [
                    '在读 ${_count(items, 'reading')}',
                    '想读 ${_count(items, 'want')}',
                    '已读 ${_count(items, 'done')}',
                  ],
                  current: _seg,
                  onChanged: (i) => setState(() => _seg = i),
                ),
              ),
              Expanded(child: _list(list, status)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBook(context),
        icon: const Icon(Icons.add),
        label: const Text('加本书',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  int _count(List<BookShelfItem> items, String s) =>
      items.where((e) => e.book.status == s).length;

  Widget _list(List<BookShelfItem> list, String status) {
    if (list.isEmpty) {
      const map = {
        'reading': ('📖', '还没有在读的书', '从「想读」翻开一本，或加一本新书吧'),
        'want': ('🌟', '想读清单是空的', '把心动的绘本先收进来'),
        'done': ('🏆', '还没有读完的书', '每一次打卡都在靠近这里'),
      };
      final e = map[status]!;
      return EmptyPlaceholder(emoji: e.$1, message: e.$2, hint: e.$3);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
      itemCount: list.length,
      itemBuilder: (c, i) => _bookCard(list[i]),
    );
  }

  Widget _bookCard(BookShelfItem it) {
    final book = it.book;
    final progress = it.progress;
    final grad = BookUi.coverGradient(book.id);
    return SoftCard(
      radius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go('/reading/book/${book.id}'),
      child: Row(
        children: [
          // 书脊封面
          Container(
            width: 52,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 4)),
              ],
            ),
            child: const Text('📕', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(book.author ?? '未知作者',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusBadge(
                        text: BookUi.statusLabel(book.status),
                        color: BookUi.statusColor(book.status)),
                    const SizedBox(width: 8),
                    Text(
                      it.logCount > 0
                          ? '已打卡 ${it.logCount} 次 · ${it.totalMinutes} 分钟'
                          : '尚未打卡',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ProgressRing(
            value: progress,
            color: BookUi.statusColor(book.status),
            label: progress == null
                ? (it.logCount > 0 ? '×${it.logCount}' : '☆')
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _addBook(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('添加一本书 📚',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '书名（必填）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorCtrl,
              decoration: const InputDecoration(hintText: '作者（选填）'),
            ),
            const SizedBox(height: 12),
            const Text('扫码识别为次要入口，V1 默认手填书名 · 套书按独立书处理',
                style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('加入书架'),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(readingRepositoryProvider).createBook(
            title: titleCtrl.text.trim(),
            author: authorCtrl.text.trim().isEmpty
                ? null
                : authorCtrl.text.trim(),
          );
    }
  }
}

final _shelfProvider = StreamProvider.autoDispose<List<BookShelfItem>>(
  (ref) => ref.watch(bookShelfServiceProvider).watchShelf(),
);
