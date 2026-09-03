import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/bookshelf/book_shelf_service.dart';

/// 书架 Tab 根：三分区（想读 / 在读 / 已读）+ 进度环。
/// 进度全部由 BookShelfService 聚合派生，页面不直接读 Books 进度字段。
class BookshelfPage extends ConsumerWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(_shelfProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('书架'),
          bottom: const TabBar(
            tabs: [Tab(text: '想读'), Tab(text: '在读'), Tab(text: '已读')],
          ),
        ),
        body: shelf.when(
          data: (items) => TabBarView(
            children: [
              _shelfList(context, items, 'want'),
              _shelfList(context, items, 'reading'),
              _shelfList(context, items, 'done'),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
        ),
      ),
    );
  }

  Widget _shelfList(
      BuildContext context, List<BookShelfItem> all, String status) {
    final items = all.where((e) => e.book.status == status).toList();
    if (items.isEmpty) return const Center(child: Text('暂无书籍'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (c, i) {
        final it = items[i];
        final progress = it.progress;
        return ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: progress != null
                ? CircularProgressIndicator(
                    value: progress, strokeWidth: 4)
                : const Icon(Icons.menu_book),
          ),
          title: Text(it.book.title),
          subtitle: Text(progress != null
              ? '进度 ${(progress * 100).toStringAsFixed(0)}%'
              : '已打卡 ${it.logCount} 次'),
          onTap: () => context.go('/reading/book/${it.book.id}'),
        );
      },
    );
  }
}

final _shelfProvider = StreamProvider.autoDispose<List<BookShelfItem>>(
  (ref) => ref.watch(bookShelfServiceProvider).watchShelf(),
);
