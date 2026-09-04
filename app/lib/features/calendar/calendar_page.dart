import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/record_display.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/daily_repository.dart';
import '../../data/repositories/child_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';
import '../records/record_tile.dart';

/// 日历主视图（日历 Tab 根）：月历 + 分类圆点 + 当日成长足迹。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateUtil.startOfDay(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final dailyStream = ref.watch(_allDailyProvider);
    final child = ref.watch(_childProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: dailyStream.when(
          data: (records) => _buildBody(records, child),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
        ),
      ),
    );
  }

  /// Demo 首页问候头部：Hi，{昵称}妈妈 👋 + 副标题 + 🐣 头像（对齐 Demo .greet）。
  Widget _greetingHeader(ChildData? child) {
    final name = child?.name.trim() ?? '';
    final title = name.isEmpty ? 'Hi，你好呀 👋' : 'Hi，$name妈妈 👋';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 2, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '今天想记点什么呀',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded, color: AppColors.primaryDeep),
            tooltip: '回到今天',
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateUtil.startOfDay(DateTime.now());
            }),
          ),
          const SizedBox(width: 2),
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Text('🐣', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<DailyRecord> records, ChildData? child) {
    // 按天聚合，供 eventLoader / 圆点使用。
    final events = <DateTime, List<DailyRecord>>{};
    for (final r in records) {
      final key = DateUtil.startOfDay(r.eventDate);
      events.putIfAbsent(key, () => []).add(r);
    }
    List<DailyRecord> loader(DateTime day) =>
        events[DateUtil.startOfDay(day)] ?? const [];

    // loader 在无记录当天返回 const []（不可变），直接 ..sort 会抛
    // "Cannot modify an unmodifiable list"。先拷贝成可变列表再排序。
    final dayRecords = List<DailyRecord>.of(loader(_selectedDay))
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        _greetingHeader(child),
        const SizedBox(height: 12),
        _calendarCard(loader),
        const SizedBox(height: 14),
        _legend(),
        const SizedBox(height: 18),
        SectionHeader(
          title: DateFormat('M月d日 EEEE', 'zh').format(_selectedDay),
          emoji: '📌',
          trailing: dayRecords.isEmpty
              ? null
              : Text('${dayRecords.length} 条',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  )),
        ),
        if (dayRecords.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyPlaceholder(
              emoji: '🌤',
              message: '这一天还没有记录',
              hint: '去「记录」Tab 添加今天的小美好吧',
            ),
          )
        else
          for (final r in dayRecords)
            RecordTimelineTile(
              record: r,
              onTap: () => context.go(
                  '/calendar/day/${DateUtil.formatDate(r.eventDate)}'),
            ),
      ],
    );
  }

  Widget _calendarCard(List<DailyRecord> Function(DateTime) loader) {
    return SoftCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: TableCalendar<DailyRecord>(
        locale: 'zh',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        calendarFormat: _format,
        availableCalendarFormats: const {
          CalendarFormat.month: '月',
          CalendarFormat.week: '周',
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
        eventLoader: loader,
        onFormatChanged: (f) => setState(() => _format = f),
        onDaySelected: (selected, focused) => setState(() {
          _selectedDay = DateUtil.startOfDay(selected);
          _focusedDay = focused;
        }),
        onPageChanged: (focused) => _focusedDay = focused,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          formatButtonTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDeep,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: AppColors.primaryDeep),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: AppColors.primaryDeep),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft),
          weekendStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.pink),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle:
              TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          weekendTextStyle:
              TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          todayDecoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.primaryDeep),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle:
              TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        calendarBuilders: CalendarBuilders<DailyRecord>(
          markerBuilder: (context, day, dayEvents) {
            if (dayEvents.isEmpty) return const SizedBox.shrink();
            // 取当天出现的分类去重，最多 3 个圆点。
            final cats = <String>{};
            for (final e in dayEvents) {
              cats.add(e.primaryCategory);
            }
            final list = cats.take(3).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in list)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.categoryColor(c),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _legend() {
    const items = ['日常', '阅读', '课表', '运动', '才艺'];
    return SoftCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final c in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.categoryColor(c),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(c,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft)),
              ],
            ),
        ],
      ),
    );
  }
}

final _allDailyProvider = StreamProvider.autoDispose<List<DailyRecord>>(
  (ref) => ref.watch(dailyRepositoryProvider).watchAll(),
);

final _childProvider = StreamProvider.autoDispose<ChildData?>(
  (ref) => ref.watch(childRepositoryProvider).watchFirst(),
);
