import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/empty_placeholder.dart';

const _weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

/// 课程色板（学校课表格子 / 课外班头像取色，按课程名稳定取一色）。
const _palette = [
  AppColors.sky,
  AppColors.mint,
  AppColors.pink,
  AppColors.lilac,
  AppColors.primaryDeep,
];

Color _courseColor(String name) =>
    _palette[name.hashCode.abs() % _palette.length];

String _extraEmoji(String name) {
  if (name.contains('画') || name.contains('绘')) return '🎨';
  if (name.contains('游泳')) return '🏊';
  if (name.contains('琴') || name.contains('音乐')) return '🎹';
  if (name.contains('舞')) return '💃';
  if (name.contains('球') || name.contains('运动') || name.contains('体')) {
    return '⚽';
  }
  if (name.contains('棋')) return '♟️';
  if (name.contains('英') || name.contains('语')) return '🔤';
  if (name.contains('数')) return '🔢';
  if (name.contains('书') || name.contains('写')) return '✍️';
  if (name.contains('科学')) return '🔬';
  return '📌';
}

final _scheduleProvider = StreamProvider.autoDispose<List<ScheduleItem>>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchAll(),
);

/// 课表管理（我的 → 课表）：学校课表周视图网格 + 课外班周期卡片。
class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(_scheduleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryDeep),
            tooltip: '添加课程',
            onPressed: () => showAddCourseSheet(context),
          ),
        ],
      ),
      body: stream.when(
        data: (items) {
          final school = items.where((e) => e.type != 'extra').toList();
          final extra = items.where((e) => e.type == 'extra').toList();
          if (school.isEmpty && extra.isEmpty) {
            return EmptyPlaceholder(
              emoji: '📚',
              message: '还没有课程',
              hint: '点右上角或下方按钮，把每周课程排进来吧',
              action: FilledButton.icon(
                onPressed: () => showAddCourseSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('添加课程'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            children: [
              if (school.isNotEmpty) ...[
                const _SectionTitle('🏫 学校课表（周）'),
                const SizedBox(height: 10),
                _SchoolGrid(items: school),
                const SizedBox(height: 20),
              ],
              const _SectionTitle('🎨 课外班（周期规则）'),
              const SizedBox(height: 10),
              if (extra.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '还没有课外班，点下方添加吧～',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                )
              else
                for (final it in extra..sort(_cmp)) _ExtraClassCard(item: it),
              const SizedBox(height: 12),
              _AddExtraButton(
                onTap: () =>
                    showAddCourseSheet(context, initialType: 'extra'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  static int _cmp(ScheduleItem a, ScheduleItem b) {
    final w = a.weekday.compareTo(b.weekday);
    return w != 0 ? w : a.startTime.compareTo(b.startTime);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }
}

/// 学校课表周视图：上午 / 下午 两行 × 工作日列，格子内为课程 chip。
class _SchoolGrid extends StatelessWidget {
  const _SchoolGrid({required this.items});
  final List<ScheduleItem> items;

  int _hour(String t) => int.tryParse(t.split(':').first) ?? 0;

  @override
  Widget build(BuildContext context) {
    // 展示的工作日：默认周一~周五，若有周末课程则并入。
    final present = items.map((e) => e.weekday).toSet();
    final days = <int>{1, 2, 3, 4, 5, ...present}.toList()..sort();

    List<ScheduleItem> cell(int wd, bool morning) => items
        .where((e) =>
            e.weekday == wd && (morning ? _hour(e.startTime) < 12 : _hour(e.startTime) >= 12))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return SoftCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        children: [
          // 表头
          Row(
            children: [
              const SizedBox(width: 30),
              for (final wd in days)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayNames[wd - 1],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _row('上午', days, (wd) => cell(wd, true)),
          const SizedBox(height: 6),
          _row('下午', days, (wd) => cell(wd, false)),
        ],
      ),
    );
  }

  Widget _row(String label, List<int> days,
      List<ScheduleItem> Function(int wd) cellOf) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ),
          for (final wd in days)
            Expanded(child: _Cell(courses: cellOf(wd))),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.courses});
  final List<ScheduleItem> courses;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(3),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('—',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
      );
    }
    return Column(
      children: [
        for (final c in courses)
          Container(
            margin: const EdgeInsets.all(3),
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _courseColor(c.courseName),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              c.courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

/// 课外班周期卡片：圆形 emoji 头像 + 课程名（大字）+ 规则（小字）+ ⋯ 菜单。
class _ExtraClassCard extends ConsumerWidget {
  const _ExtraClassCard({required this.item});
  final ScheduleItem item;

  String _rule() {
    const rec = {
      'weekly': '每周',
      'biweekly': '隔周',
      'monthly': '每月',
      'once': '单次',
    };
    final prefix = rec[item.recurrence] ?? '每周';
    final wd = '周${_weekdayNames[(item.weekday - 1).clamp(0, 6)]}';
    var s = '$prefix$wd ${item.startTime}-${item.endTime}';
    if (item.endDate != null) {
      s += ' · 至 ${DateFormat('yyyy-MM').format(item.endDate!)}';
    }
    return s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _courseColor(item.courseName);
    return SoftCard(
      radius: 18,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(_extraEmoji(item.courseName),
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.courseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    _rule(),
                    if (item.location != null && item.location!.isNotEmpty)
                      item.location!,
                    if (item.teacher != null && item.teacher!.isNotEmpty)
                      item.teacher!,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.inkSoft),
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('删除整门课'),
                    content: Text('确定删除「${item.courseName}」吗？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('删除')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(scheduleRepositoryProvider).remove(item.id);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('🗑 删除整门课')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddExtraButton extends StatelessWidget {
  const _AddExtraButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.primaryDeep, size: 20),
              SizedBox(width: 6),
              Text(
                '添加课外班',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全局复用的「添加课程」底部弹层（课表 / 底部 + 号共用）。
/// [initialType] 预选 school / extra。
Future<void> showAddCourseSheet(BuildContext context,
    {String initialType = 'school'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _AddCourseSheet(initialType: initialType),
  );
}

class _AddCourseSheet extends ConsumerStatefulWidget {
  const _AddCourseSheet({this.initialType = 'school'});
  final String initialType;

  @override
  ConsumerState<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends ConsumerState<_AddCourseSheet> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  late String _type = widget.initialType; // school / extra
  final Set<int> _weekdays = {}; // 1~7
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _weekdays.isNotEmpty &&
      _start != null &&
      _end != null;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(scheduleRepositoryProvider).addForWeekdays(
            courseName: _nameCtrl.text.trim(),
            weekdays: _weekdays.toList()..sort(),
            startTime: _fmt(_start!),
            endTime: _fmt(_end!),
            type: _type,
            location: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
            teacher: _teacherCtrl.text.trim().isEmpty
                ? null
                : _teacherCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课程已添加 🎉')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('添加课程',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 16),
            Row(
              children: [
                _typeChip('school', '🏫 学校'),
                const SizedBox(width: 10),
                _typeChip('extra', '🎨 课外班'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '课程名称 *',
                hintText: '如：数学 / 钢琴 / 游泳',
              ),
            ),
            const SizedBox(height: 16),
            const Text('上课星期 *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (int wd = 1; wd <= 7; wd++) _weekdayChip(wd)],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _timeField('开始', _start, () => _pickTime(true))),
                const SizedBox(width: 12),
                Expanded(child: _timeField('结束', _end, () => _pickTime(false))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: '地点（选填）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teacherCtrl,
              decoration: const InputDecoration(labelText: '老师（选填）'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primaryDeep : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.primaryDeep : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _weekdayChip(int wd) {
    final selected = _weekdays.contains(wd);
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _weekdays.remove(wd) : _weekdays.add(wd);
      }),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDeep : AppColors.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primaryDeep : AppColors.line,
            width: 1.5,
          ),
        ),
        child: Text(
          _weekdayNames[wd - 1],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, TimeOfDay? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Text(
              value == null ? '$label时间 *' : '$label ${_fmt(value)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: value == null ? AppColors.inkSoft : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
