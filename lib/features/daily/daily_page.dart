import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_placeholder.dart';

/// 日常事项记录页面。
class DailyPage extends ConsumerWidget {
  const DailyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('日常记录')),
      body: const EmptyPlaceholder(
        message: '还没有记录，点击右下角添加吧',
        icon: Icons.edit_note,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
