import 'package:flutter/material.dart';

import '../models/material.dart' as model;

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({
    super.key,
    required this.initialMaterials,
    this.onCreated,
    this.onUpdated,
    this.onDeleted,
  });

  final List<model.Material> initialMaterials;
  final ValueChanged<model.Material>? onCreated;
  final ValueChanged<model.Material>? onUpdated;
  final ValueChanged<String>? onDeleted;

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  late List<model.Material> _materials;
  final List<String> _customCategories = [];
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    _materials = List<model.Material>.from(widget.initialMaterials);
  }

  @override
  void didUpdateWidget(covariant MaterialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = {for (final item in widget.initialMaterials) item.id: item};
    final local = {for (final item in _materials) item.id: item};
    local.addAll(incoming);
    if (local.length != _materials.length || incoming.keys.any((id) => !_materials.any((item) => item.id == id))) {
      setState(() => _materials = local.values.toList());
    }
  }

  List<String> get _categories => {
        ..._customCategories,
        ..._materials.map((item) => item.category).where((item) => item.isNotEmpty),
      }.toList();

  List<model.Material> get _visibleMaterials => _categoryFilter.isEmpty
      ? _materials
      : _materials.where((item) => item.category == _categoryFilter).toList();

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新增类别'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: '类别名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (value != null && value.isNotEmpty && !_categories.contains(value)) {
      setState(() => _customCategories.add(value));
    }
  }

  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagController = TextEditingController();
    var category = _categories.isNotEmpty ? _categories.first : '';
    final result = await showDialog<model.Material>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新增学习素材'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: '标题')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: category.isEmpty ? null : category,
                    decoration: const InputDecoration(labelText: '类别'),
                    items: _categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                    onChanged: (value) => setDialogState(() => category = value ?? ''),
                  ),
                ),
                IconButton(onPressed: () async { await _addCategory(); if (mounted) setDialogState(() { if (_categories.isNotEmpty) category = _categories.last; }); }, icon: const Icon(Icons.add_circle_outline), tooltip: '新增类别'),
              ]),
              TextField(controller: tagController, decoration: const InputDecoration(labelText: '标签（用逗号分隔）')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: '内容'), maxLines: 4),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final tags = tagController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                Navigator.pop(dialogContext, model.Material(id: 'material-${DateTime.now().microsecondsSinceEpoch}', title: title, content: contentController.text, category: category, tags: tags, favorite: false, createdAt: DateTime.now()));
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    titleController.dispose(); contentController.dispose(); tagController.dispose();
    if (result != null) { setState(() => _materials.insert(0, result)); widget.onCreated?.call(result); }
  }

  void _toggleFavorite(model.Material item) {
    final updated = item.copyWith(favorite: !item.favorite);
    final index = _materials.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    setState(() => _materials[index] = updated);
    widget.onUpdated?.call(updated);
  }

  Future<void> _deleteMaterial(model.Material item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('删除素材'), content: Text(item.title), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('删除'))]));
    if (confirmed == true) { setState(() => _materials.removeWhere((value) => value.id == item.id)); widget.onDeleted?.call(item.id); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('积累'),
        actions: [
          IconButton(onPressed: _addCategory, icon: const Icon(Icons.label_outline), tooltip: '管理类别'),
          PopupMenuButton<String>(onSelected: (value) => setState(() => _categoryFilter = value == '全部' ? '' : value), itemBuilder: (context) => ['全部', ..._categories].map((value) => PopupMenuItem(value: value, child: Text(value))).toList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addMaterial, child: const Icon(Icons.add)),
      body: _visibleMaterials.isEmpty
          ? const Center(child: Text('还没有学习素材'))
          : ListView.builder(
              itemCount: _visibleMaterials.length,
              itemBuilder: (context, index) {
                final item = _visibleMaterials[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text([item.category, ...item.tags].where((e) => e.isNotEmpty).join(' · ')),
                  trailing: IconButton(icon: Icon(item.favorite ? Icons.star : Icons.star_border), onPressed: () => _toggleFavorite(item)),
                  onTap: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(item.title), content: SingleChildScrollView(child: Text(item.content)), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('关闭'))])),
                  onLongPress: () => _deleteMaterial(item),
                );
              },
            ),
    );
  }
}
