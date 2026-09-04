import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/reading_repository.dart';
import '../../shared/widgets/input_widgets.dart';

/// 阅读打卡 bottom sheet：进度（绘本二态 / 按页 / 按章）+ 时长 + 心情 + 感想 + 日期。
/// 只追加一条 ReadingLog，进度状态跃迁交由 ReadingRepository.addLog 判定。
class ReadingCheckInSheet extends ConsumerStatefulWidget {
  const ReadingCheckInSheet({super.key, required this.book});

  final Book book;

  static Future<void> show(BuildContext context, {required Book book}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => ReadingCheckInSheet(book: book),
    );
  }

  @override
  ConsumerState<ReadingCheckInSheet> createState() =>
      _ReadingCheckInSheetState();
}

class _ReadingCheckInSheetState extends ConsumerState<ReadingCheckInSheet> {
  final _pageCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _minutes = 15;
  String? _mood;
  DateTime _date = DateTime.now();
  bool _finished = false;
  bool _saving = false;

  /// 进度模式：page(按页) / chapter(按章) / picture(绘本二态)。
  late String _mode = _defaultMode();

  String _defaultMode() {
    if ((widget.book.totalPages ?? 0) > 0) return 'page';
    if ((widget.book.totalChapters ?? 0) > 0) return 'chapter';
    return 'picture';
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _chapterCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3D6C2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('给《${widget.book.title}》打卡 📖',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('读到哪儿了'),
                      _modeSelector(),
                      const SizedBox(height: 10),
                      _progressInput(),
                      const SizedBox(height: 18),
                      _label('本次阅读时长'),
                      DurationQuickPicker(
                        value: _minutes,
                        onChanged: (v) => setState(() => _minutes = v),
                      ),
                      const SizedBox(height: 18),
                      _label('孩子心情（选填）'),
                      MoodPicker(
                        value: _mood,
                        onChanged: (v) => setState(() => _mood = v),
                      ),
                      const SizedBox(height: 18),
                      _label('感想（选填）'),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            hintText: '今天读到哪个情节，宝贝有什么反应…'),
                      ),
                      const SizedBox(height: 18),
                      _label('日期'),
                      _datePicker(),
                      const SizedBox(height: 14),
                      _finishToggle(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中…' : '完成打卡'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft)),
      );

  Widget _modeSelector() {
    const modes = [
      ('picture', '🖼 绘本'),
      ('page', '# 按页'),
      ('chapter', '§ 按章'),
    ];
    return Wrap(
      spacing: 8,
      children: [
        for (final m in modes)
          GestureDetector(
            onTap: () => setState(() => _mode = m.$1),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _mode == m.$1 ? AppColors.mintSoft : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _mode == m.$1 ? AppColors.mint : AppColors.line,
                    width: 2),
              ),
              child: Text(m.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _mode == m.$1
                          ? const Color(0xFF3AA88F)
                          : AppColors.inkSoft)),
            ),
          ),
      ],
    );
  }

  Widget _progressInput() {
    switch (_mode) {
      case 'page':
        return TextField(
          controller: _pageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '读到第几页',
            suffixText: widget.book.totalPages != null
                ? '/ ${widget.book.totalPages} 页'
                : null,
          ),
        );
      case 'chapter':
        return TextField(
          controller: _chapterCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '读到第几章',
            suffixText: widget.book.totalChapters != null
                ? '/ ${widget.book.totalChapters} 章'
                : null,
          ),
        );
      case 'picture':
      default:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('绘本按"读一次"记录，无需填页数～勾选下方"本册读完"即完成本册。',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3AA88F))),
        );
    }
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('zh'),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded,
                size: 18, color: AppColors.primaryDeep),
            const SizedBox(width: 8),
            Text(DateFormat('yyyy年M月d日', 'zh').format(_date),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  Widget _finishToggle() {
    return GestureDetector(
      onTap: () => setState(() => _finished = !_finished),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _finished ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _finished ? AppColors.primary : AppColors.line, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              _finished
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: _finished ? AppColors.primaryDeep : AppColors.inkSoft,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('本册读完 ✅',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            const Text('套书按独立书处理',
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    int? pageTo;
    int? chapterIndex;
    String? chapter;
    if (_mode == 'page') {
      pageTo = int.tryParse(_pageCtrl.text.trim());
    } else if (_mode == 'chapter') {
      chapterIndex = int.tryParse(_chapterCtrl.text.trim());
      if (chapterIndex != null) chapter = '第 $chapterIndex 章';
    }
    await ref.read(readingRepositoryProvider).addLogFields(
          bookId: widget.book.id,
          readDate: _date,
          pageTo: pageTo,
          chapterIndex: chapterIndex,
          chapter: chapter,
          durationMinutes: _minutes ?? 0,
          mood: _mood,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          markFinished: _finished,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打卡成功，真棒！🎉')));
    }
  }
}
