import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_page.dart';
import '../../features/daily/daily_page.dart';
import '../../features/reading/reading_page.dart';
import '../../features/schedule/schedule_page.dart';
import '../../features/report/report_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/daily',
        name: 'daily',
        builder: (context, state) => const DailyPage(),
      ),
      GoRoute(
        path: '/reading',
        name: 'reading',
        builder: (context, state) => const ReadingPage(),
      ),
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) => const ReportPage(),
      ),
    ],
  );
});
