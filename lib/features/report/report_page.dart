import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_placeholder.dart';

/// 周报生成与查看页面。
class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('周报')),
      body: const EmptyPlaceholder(
        message: '暂无周报，生成一份看看本周成长吧',
        icon: Icons.assessment,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.auto_awesome),
        label: const Text('生成周报'),
      ),
    );
  }
}
