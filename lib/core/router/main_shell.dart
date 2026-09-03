import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/records/quick_add_sheet.dart';
import '../../features/schedule/schedule_page.dart';

/// 底部导航骨架：4 Tab（日历/记录/阅读/我的）+ 正中悬浮「+」快速记录按钮。
/// indexedStack 保各分支独立返回栈；「+」为全局快速记录入口，居中凹槽悬浮。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _goBranch(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  /// 中间「+」→ 弹出快速记录选择：记一笔日常 / 记录阅读 / 添加课程。
  void _openQuickRecord(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '想记点什么呀 ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _QuickOption(
                  emoji: '📝',
                  bg: AppColors.primarySoft,
                  title: '记一笔日常',
                  subtitle: '文字 · 照片 · 心情 · 标签',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    QuickAddSheet.show(context);
                  },
                ),
                const SizedBox(height: 10),
                _QuickOption(
                  emoji: '📖',
                  bg: AppColors.mintSoft,
                  title: '记录阅读',
                  subtitle: '去书架挑一本书打卡',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.go('/reading');
                  },
                ),
                const SizedBox(height: 10),
                _QuickOption(
                  emoji: '🏫',
                  bg: AppColors.skySoft,
                  title: '添加课程',
                  subtitle: '把每周课程排进课表',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showAddCourseSheet(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 四个 Tab 根路由展示「+」快速记录按钮（精确匹配，任何二级子路径都不展示）。
  static const _fabRoots = {'/calendar', '/records', '/reading', '/mine'};

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    // 监听路由变化：分支内 push 子页（如 /records/timer、/calendar/day/xxx）
    // 不会重建 shell，必须监听 routerDelegate 才能拿到最新完整路径并刷新 FAB。
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        // 基于当前完整路径精确判断：仅 /calendar、/records 根页面显示，
        // 子页面（/records/xxx、/calendar/day/xxx 等）一律隐藏。
        final showFab = _fabRoots.contains(path);
        return Scaffold(
          body: shell,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: showFab
              ? SizedBox(
                  height: 60,
                  width: 60,
                  child: FloatingActionButton(
                    heroTag: 'quick_record_fab',
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    onPressed: () => _openQuickRecord(context),
                    child: const Icon(Icons.add, size: 32),
                  ),
                )
              : null,
          bottomNavigationBar: BottomAppBar(
            color: AppColors.card,
            elevation: 10,
            shadowColor: AppColors.shadow,
            // 有 FAB 时才留凹槽，否则用平底避免中间出现空缺
            shape: showFab ? const CircularNotchedRectangle() : null,
            notchMargin: showFab ? 8 : 0,
            height: 66,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.calendar_month,
                  label: '日历',
                  selected: shell.currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),
                _NavItem(
                  icon: Icons.edit_note,
                  label: '记录',
                  selected: shell.currentIndex == 1,
                  onTap: () => _goBranch(1),
                ),
                // 仅在展示 FAB 时为中间凹槽留位
                if (showFab) const SizedBox(width: 64),
                _NavItem(
                  icon: Icons.menu_book,
                  label: '阅读',
                  selected: shell.currentIndex == 2,
                  onTap: () => _goBranch(2),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: '我的',
                  selected: shell.currentIndex == 3,
                  onTap: () => _goBranch(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 底部单个 Tab（图标 + 文字），选中态高亮暖橙。
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDeep : AppColors.inkSoft;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快速记录弹层中的单个选项卡。
class _QuickOption extends StatelessWidget {
  const _QuickOption({
    required this.emoji,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
