import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 底部导航骨架：indexedStack 保各分支独立返回栈。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // initialLocation:true → 再次点当前 Tab 回到该分支根，符合 Tab 语义
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '日历'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: '记录'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: '阅读'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
