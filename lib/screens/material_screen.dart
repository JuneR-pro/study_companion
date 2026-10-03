import 'package:flutter/material.dart';

import '../models/material.dart' as model;

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key, required this.initialMaterials});

  final List<model.Material> initialMaterials;

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  late List<model.Material> _materials;
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    _materials = List<model.Material>.from(widget.initialMaterials);
  }

  List<model.Material> get _visibleMaterials => _categoryFilter.isEmpty
      ? _materials
      : _materials.where((item) => item.category == _categoryFilter).toList();

  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final categoryController = TextEditingController();
    final result = await showDialog<model.Material>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增学习素材'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '内容'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                context,
                model.Material(
                  id: 'material-${DateTime.now().microsecondsSinceEpoch}',
                  title: title,
                  content: contentController.text,
                  category: categoryController.text.trim(),
                  tags: const [],
                  favorite: false,
                  createdAt: DateTime.now(),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    titleController.dispose();
    contentController.dispose();
    categoryController.dispose();
    if (result != null) setState(() => _materials.insert(0, result));
  }

  void _toggleFavorite(model.Material item) {
    final index = _materials.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    setState(() => _materials[index] = item.copyWith(favorite: !item.favorite));
  }

  Future<void> _deleteMaterial(model.Material item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除素材？'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _materials.removeWhere((value) => value.id == item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _materials
        .map((item) => item.category)
        .where((item) => item.isNotEmpty)
        .toSet();
    return Scaffold(
      appBar: AppBar(
        title: const Text('积累'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                setState(() => _categoryFilter = value == '全部' ? '' : value),
            itemBuilder: (context) => ['全部', ...categories]
                .map((value) => PopupMenuItem(value: value, child: Text(value)))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMaterial,
        child: const Icon(Icons.add),
      ),
      body: _visibleMaterials.isEmpty
          ? const Center(child: Text('还没有学习素材'))
          : ListView.builder(
              itemCount: _visibleMaterials.length,
              itemBuilder: (context, index) {
                final item = _visibleMaterials[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.category} · ${item.tags.join('、')}'),
                  trailing: IconButton(
                    icon: Icon(item.favorite ? Icons.star : Icons.star_border),
                    onPressed: () => _toggleFavorite(item),
                  ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(item.title),
                      content: Text(item.content),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                  ),
                  onLongPress: () => _deleteMaterial(item),
                );
              },
            ),
    );
  }
}
