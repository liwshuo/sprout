import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 单例。在 main() 中加载后通过 override 注入，避免全局异步读取。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main() 里通过 override 注入',
  ),
);
