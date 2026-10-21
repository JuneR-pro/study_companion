import 'package:flutter/material.dart';

import '../utils/study_theme.dart';
import '../utils/wrong_question_colors.dart';
import '../utils/wrong_question_icons.dart';

class IconColorPicker extends StatefulWidget {
  const IconColorPicker({
    super.key,
    required this.title,
    this.initialIconName = 'folder',
    this.initialColor,
  });

  final String title;
  final String initialIconName;
  final Color? initialColor;

  static Future<(String, Color)> show(
    BuildContext context, {
    required String title,
    String iconName = 'folder',
    Color? color,
  }) async {
    final result = await showDialog<(String, Color)>(
      context: context,
      builder: (_) => IconColorPicker(title: title, initialIconName: iconName, initialColor: color),
    );
    return result ?? (iconName, color ?? const Color(0xFF9A8769));
  }

  @override
  State<IconColorPicker> createState() => _IconColorPickerState();
}

class _IconColorPickerState extends State<IconColorPicker> {
  late String _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIconName;
    _selectedColor = widget.initialColor ?? WrongQuestionColors.palette.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WrongQuestionIcons.available.map((option) {
                final selected = option.name == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = option.name),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? _selectedColor.withValues(alpha: .18) : const Color(0xFFF5F2ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _selectedColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(option.icon, size: 22, color: selected ? _selectedColor : StudyTheme.ink),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: WrongQuestionColors.palette.map((color) {
                final selected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? StudyTheme.ink : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('自定义', style: TextStyle(fontSize: 13, color: StudyTheme.muted)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showColorPicker(context);
                  if (picked != null) setState(() => _selectedColor = picked);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: StudyTheme.line),
                  ),
                  child: const Icon(Icons.colorize, size: 18, color: StudyTheme.muted),
                ),
              ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_selectedIcon, _selectedColor)),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Future<Color?> showColorPicker(BuildContext context) async {
    Color picked = _selectedColor;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 8),
                    const Text('色相', style: TextStyle(fontSize: 13)),
                    Slider(
                      value: HSVColor.fromColor(picked).hue,
                      min: 0, max: 360,
                      onChanged: (v) => setDialogState(() {
                        final hsv = HSVColor.fromColor(picked);
                        picked = hsv.withHue(v).toColor();
                      }),
                    ),
                    const Text('饱和度', style: TextStyle(fontSize: 13)),
                    Slider(
                      value: HSVColor.fromColor(picked).saturation,
                      min: 0, max: 1,
                      onChanged: (v) => setDialogState(() {
                        final hsv = HSVColor.fromColor(picked);
                        picked = hsv.withSaturation(v).toColor();
                      }),
                    ),
                    const Text('明度', style: TextStyle(fontSize: 13)),
                    Slider(
                      value: HSVColor.fromColor(picked).value,
                      min: 0.2, max: 1,
                      onChanged: (v) => setDialogState(() {
                        final hsv = HSVColor.fromColor(picked);
                        picked = hsv.withValue(v).toColor();
                      }),
                    ),
                  ]),
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: picked,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: StudyTheme.line),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, picked), child: const Text('确定')),
          ],
        );
      }),
    );
  }
}
