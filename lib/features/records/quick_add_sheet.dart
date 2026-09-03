import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/record_display.dart';
import '../../data/repositories/daily_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/input_widgets.dart';

/// 快速记录 bottom sheet：文字 + 多图 + 心情 + 标签 + 日期。
/// 记录只用标签分类，无独立"类型"维度（category = 首个选中标签，仅用于着色）。
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.initialDate});

  final DateTime? initialDate;

  static Future<bool?> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => QuickAddSheet(initialDate: initialDate),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _ctrl = TextEditingController();
  final Set<String> _tags = {};
  final List<String> _images = [];
  String? _mood;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isPast => DateUtils.dateOnly(_date)
      .isBefore(DateUtils.dateOnly(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
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
              const Text('记录一刻 ✨',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('发生了什么？'),
                      TextField(
                        controller: _ctrl,
                        autofocus: true,
                        maxLines: 3,
                        minLines: 2,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: '今天宝贝有什么小美好…',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label('配图（选填）'),
                      _photoGrid(),
                      const SizedBox(height: 18),
                      _label('心情（选填）'),
                      MoodPicker(
                        value: _mood,
                        onChanged: (v) => setState(() => _mood = v),
                      ),
                      const SizedBox(height: 18),
                      _label('贴个标签（选填，可多选）'),
                      TagSelector(
                        selected: _tags,
                        onChanged: (v) => setState(() => _tags
                          ..clear()
                          ..addAll(v)),
                      ),
                      const SizedBox(height: 18),
                      _label('日期'),
                      _datePicker(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中…' : '保存记录'),
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

  Widget _photoGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _images.length; i++)
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(14),
                  image: DecorationImage(
                    image: _imageProvider(_images[i]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(i)),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.line, width: 2, style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined,
                    color: AppColors.inkSoft, size: 22),
                SizedBox(height: 2),
                Text('加图',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path); // 占位：真机为 FileImage，桌面预览降级
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: _pickDate,
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
            Text(
              DateFormat('yyyy年M月d日 EEEE', 'zh').format(_date),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const Spacer(),
            if (_isPast)
              const StatusBadge(text: '补记', color: AppColors.lilac),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage();
      if (files.isNotEmpty) {
        setState(() => _images.addAll(files.map((f) => f.path)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法访问相册')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先写点什么吧～')));
      return;
    }
    setState(() => _saving = true);
    final tags = _tags.toList();
    await ref.read(dailyRepositoryProvider).addFields(
          title: title,
          tags: tags.isEmpty ? null : encodeStringList(tags),
          imagePaths:
              _images.isEmpty ? null : encodeStringList(_images),
          category: tags.isEmpty ? null : tags.first,
          mood: _mood,
          eventDate: _date,
        );
    if (mounted) Navigator.pop(context, true);
  }
}
