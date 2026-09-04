import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/onboarding_controller.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/calendar/day_detail_page.dart';
import '../../features/records/records_page.dart';
import '../../features/timer/timer_page.dart';
import '../../features/reading/bookshelf_page.dart';
import '../../features/reading/book_detail_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/schedule/schedule_page.dart';
import '../../features/report/report_list_page.dart';
import '../../features/report/report_detail_page.dart';
import '../../features/settings/settings_page.dart';
import 'main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _calKey = GlobalKey<NavigatorState>();
final _recKey = GlobalKey<NavigatorState>();
final _readKey = GlobalKey<NavigatorState>();
final _mineKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/calendar',
    // onboarding 状态变化时驱动 redirect 重算（onboardedListenableProvider 暴露一个 Listenable）
    refreshListenable: ref.watch(onboardedListenableProvider),
    // 未建孩子档案 → 强制进 onboarding；已建档但停留在 onboarding → 放行到主界面
    redirect: (context, state) {
      final onboarded = ref.read(onboardedProvider); // bool，读 SharedPreferences/Child 表
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded) return atOnboarding ? null : '/onboarding';
      if (atOnboarding) return '/calendar';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey, // 顶层路由，无底部栏
        builder: (c, s) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => MainShell(shell: shell), // 底部 4 Tab 骨架
        branches: [
          // 四个分支仅保留根页面，二级页面已提升为顶层全屏路由（脱离 Shell）。
          StatefulShellBranch(navigatorKey: _calKey, routes: [
            GoRoute(
              path: '/calendar',
              builder: (c, s) => const CalendarPage(),
            ),
          ]),
          StatefulShellBranch(navigatorKey: _recKey, routes: [
            GoRoute(
              path: '/records',
              builder: (c, s) => const RecordsPage(),
            ),
          ]),
          StatefulShellBranch(navigatorKey: _readKey, routes: [
            GoRoute(
              path: '/reading',
              builder: (c, s) => const BookshelfPage(),
            ),
          ]),
          StatefulShellBranch(navigatorKey: _mineKey, routes: [
            GoRoute(
              path: '/mine',
              builder: (c, s) => const ProfilePage(),
            ),
          ]),
        ],
      ),
      // ===== 二级页面：顶层全屏路由（root navigator，无底部 Tab）=====
      // 完整路径与原嵌套路径保持一致，调用方 context.push/go 无需改动。
      GoRoute(
        path: '/calendar/day/:date',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => DayDetailPage(date: s.pathParameters['date']!),
      ),
      GoRoute(
        path: '/records/timer',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const TimerPage(),
      ),
      GoRoute(
        path: '/reading/book/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) =>
            BookDetailPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/mine/schedule',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const SchedulePage(),
      ),
      GoRoute(
        path: '/mine/reports',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const ReportListPage(),
      ),
      GoRoute(
        path: '/mine/reports/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) =>
            ReportDetailPage(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/mine/settings',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const SettingsPage(),
      ),
    ],
  );
});
