import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/domain/report/report_scheduler.dart';

void main() {
  group('nextSunday20', () {
    test('周四 14:00 → 距本周日 20:00', () {
      // 2026-09-03 是周四
      final now = DateTime(2026, 9, 3, 14);
      final d = nextSunday20(now);
      final fire = now.add(d);
      expect(fire.weekday, DateTime.sunday);
      expect(fire.hour, 20);
      expect(fire, DateTime(2026, 9, 6, 20));
    });

    test('周日 21:00（已过点）→ 顺延到下周日 20:00', () {
      final now = DateTime(2026, 9, 6, 21); // 周日晚
      final fire = now.add(nextSunday20(now));
      expect(fire.weekday, DateTime.sunday);
      expect(fire, DateTime(2026, 9, 13, 20));
    });

    test('周日 19:00（未到点）→ 当天 20:00', () {
      final now = DateTime(2026, 9, 6, 19);
      final fire = now.add(nextSunday20(now));
      expect(fire, DateTime(2026, 9, 6, 20));
    });
  });
}
