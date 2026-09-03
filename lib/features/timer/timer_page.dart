import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/timer/timer_session.dart';
import '../../data/repositories/daily_repository.dart';

/// 活动计时器（MVP：仅开始 / 结束，无暂停）。进行中态持久化，防杀恢复。
class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(timerSessionProvider);
    final controller = ref.read(timerSessionProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('活动计时器')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active == null ? Icons.play_circle_outline : Icons.timelapse,
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              active == null
                  ? '未开始'
                  : '进行中 · 已计 ${controller.elapsedMinutes()} 分钟',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            if (active == null)
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始计时'),
                onPressed: () => controller.start(scene: 'generic'),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error),
                icon: const Icon(Icons.stop),
                label: const Text('结束并记录'),
                onPressed: () => _finish(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(timerSessionProvider.notifier);
    final minutes = controller.finish(); // 结束会话并清持久化态
    // 计时会话本身不落表；结束后落一条 DailyRecord（source=timer）
    await ref.read(dailyRepositoryProvider).addFields(
          title: '活动计时 $minutes 分钟',
          source: 'timer',
          eventDate: DateTime.now(),
          durationMinutes: minutes,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已记录 $minutes 分钟')));
    }
  }
}
