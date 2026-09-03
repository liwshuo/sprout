import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/providers/shared_prefs_provider.dart';
import 'domain/report/report_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // workmanager：注册后台入口 + 排下一个周日 20:00 的周报任务（自重排链）。
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await scheduleWeekly();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SproutApp(),
    ),
  );
}
