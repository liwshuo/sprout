import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_prefs_provider.dart';

const _kOnboardedKey = 'onboarded';

/// Onboarding 完成标志的内存态 + 持久化。作为 go_router 的 refreshListenable，
/// 状态翻转时驱动 redirect 重算。
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._prefs) {
    _onboarded = _prefs.getBool(_kOnboardedKey) ?? false;
  }

  final SharedPreferences _prefs;
  bool _onboarded = false;

  bool get onboarded => _onboarded;

  /// 完成建档：写本地标志并通知路由重算。
  Future<void> complete() async {
    if (_onboarded) return;
    _onboarded = true;
    await _prefs.setBool(_kOnboardedKey, true);
    notifyListeners();
  }

  /// 调试用：重置 onboarding。
  Future<void> reset() async {
    _onboarded = false;
    await _prefs.remove(_kOnboardedKey);
    notifyListeners();
  }
}

final onboardingControllerProvider =
    ChangeNotifierProvider<OnboardingController>(
  (ref) => OnboardingController(ref.watch(sharedPreferencesProvider)),
);

/// redirect 内同步读取的 bool。
final onboardedProvider = Provider<bool>(
  (ref) => ref.watch(onboardingControllerProvider).onboarded,
);

/// 供 GoRouter.refreshListenable 监听。
final onboardedListenableProvider = Provider<Listenable>(
  (ref) => ref.watch(onboardingControllerProvider),
);
