import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_prefs_provider.dart';

const _kTimerKey = 'active_timer_session';
const _kMaxRunHours = 6; // 超长兜底阈值

/// 进行中会话的持久化结构（MVP：pausedAt/accumulatedMinutes 恒为 null/0，预留 V2 暂停能力）。
class ActiveTimer {
  final String scene; // reading | generic
  final DateTime startAt;
  final int? linkedBookId;
  final DateTime? pausedAt; // 预留 V2
  final int accumulatedMinutes; // 预留 V2

  const ActiveTimer({
    required this.scene,
    required this.startAt,
    this.linkedBookId,
    this.pausedAt,
    this.accumulatedMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
        'scene': scene,
        'startAt': startAt.toIso8601String(),
        'linkedBookId': linkedBookId,
        'pausedAt': pausedAt?.toIso8601String(),
        'accumulatedMinutes': accumulatedMinutes,
      };

  factory ActiveTimer.fromJson(Map<String, dynamic> j) => ActiveTimer(
        scene: j['scene'] as String,
        startAt: DateTime.parse(j['startAt'] as String),
        linkedBookId: j['linkedBookId'] as int?,
        pausedAt: j['pausedAt'] == null
            ? null
            : DateTime.parse(j['pausedAt'] as String),
        accumulatedMinutes: (j['accumulatedMinutes'] as int?) ?? 0,
      );
}

/// 冷启动恢复结果：交给 UI 决定弹窗。
enum RestoreAction { none, resume, confirmOverlong }

/// 活动计时器状态机。计时会话本身不落表，仅进行中态持久化到 SharedPreferences（防杀恢复）。
class TimerSessionController extends StateNotifier<ActiveTimer?> {
  TimerSessionController(this._prefs) : super(null);

  final SharedPreferences _prefs;

  /// 开始计时：立即把 {scene, startAt, linkedBookId} 写入 SharedPreferences。
  Future<void> start({required String scene, int? linkedBookId}) async {
    final t = ActiveTimer(
      scene: scene,
      startAt: DateTime.now(),
      linkedBookId: linkedBookId,
    );
    state = t;
    await _prefs.setString(_kTimerKey, jsonEncode(t.toJson()));
  }

  /// 结束：返回本次时长（分钟）；超长交由 UI 二次确认，不在此静默落库。
  int finish() {
    final t = state;
    if (t == null) return 0;
    final minutes = DateTime.now().difference(t.startAt).inMinutes;
    _clear();
    return minutes;
  }

  /// 放弃：不落库，清理进行中态。
  void discard() => _clear();

  /// 冷启动检测未结束会话：超过阈值判定为"忘记结束"，返回 confirmOverlong 交 UI 处理。
  RestoreAction detectOnLaunch() {
    final raw = _prefs.getString(_kTimerKey);
    if (raw == null) return RestoreAction.none;
    final t = ActiveTimer.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    state = t;
    final elapsed = DateTime.now().difference(t.startAt);
    return elapsed.inHours >= _kMaxRunHours
        ? RestoreAction.confirmOverlong
        : RestoreAction.resume;
  }

  /// 当前进行中会话已计分钟数（供 UI 展示）。
  int elapsedMinutes() {
    final t = state;
    if (t == null) return 0;
    return DateTime.now().difference(t.startAt).inMinutes;
  }

  Future<void> _clear() async {
    state = null;
    await _prefs.remove(_kTimerKey);
  }
}

final timerSessionProvider =
    StateNotifierProvider<TimerSessionController, ActiveTimer?>(
  (ref) => TimerSessionController(ref.watch(sharedPreferencesProvider)),
);
