import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 首页 —— 日历视图与功能入口。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_HomeEntry>[
      const _HomeEntry('日常记录', Icons.edit_note, '/daily'),
      const _HomeEntry('阅读打卡', Icons.menu_book, '/reading'),
      const _HomeEntry('课表管理', Icons.calendar_month, '/schedule'),
      const _HomeEntry('周报', Icons.assessment, '/report'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sprout · 成长记录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.today, size: 40),
                    const SizedBox(width: 16),
                    Text(
                      '今天',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: entries
                    .map(
                      (e) => Card(
                        child: InkWell(
                          onTap: () => context.push(e.route),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(e.icon, size: 40),
                              const SizedBox(height: 8),
                              Text(e.label),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEntry {
  final String label;
  final IconData icon;
  final String route;
  const _HomeEntry(this.label, this.icon, this.route);
}
