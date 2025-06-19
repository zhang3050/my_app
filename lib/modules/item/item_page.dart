import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'item.dart';
import '../../modules/log/log_service.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late Box<Item> _box;
  final List<String> _tags = ['家居', '娱乐', '办公', '学习', '运动', '其他'];

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Item>('items');
  }

  void _addOrEditItem({Item? item, int? index}) async {
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemEditDialog(item: item, tags: _tags),
    );
    if (result != null) {
      if (item == null) {
        await _box.add(result);
      } else if (index != null) {
        await _box.putAt(index, result);
      }
      setState(() {});
    }
  }

  void _deleteItem(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  String _formatPrice(double price) {
    // 截断到两位小数
    int p = (price * 100).truncate();
    return (p / 100).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (context, Box<Item> box, _) {
            if (box.isEmpty) {
              return const Center(child: Text('暂无物品，点击右下角添加', style: TextStyle(fontSize: 18)));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index)!;
                return GestureDetector(
                  onTap: () => _addOrEditItem(item: item, index: index),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('删除物品'),
                        content: Text('确定要删除"${item.name}"吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('删除', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _deleteItem(index);
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('标签: ${item.tag}', style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('价格: ¥${_formatPrice(item.price)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addOrEditItem(),
          child: const Icon(Icons.add),
          tooltip: '添加物品',
        ),
      );
    } catch (e, s) {
      LogService.addError('物品管理页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }
}

class ItemEditDialog extends StatefulWidget {
  final Item? item;
  final List<String> tags;
  const ItemEditDialog({super.key, this.item, required this.tags});

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  String _tag = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _tag = widget.item?.tag ?? widget.tags.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '添加物品' : '编辑物品'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '物品名称'),
            ),
            DropdownButtonFormField<String>(
              value: _tag,
              items: widget.tags.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _tag = v ?? widget.tags.first),
              decoration: const InputDecoration(labelText: '标签'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: '价格'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Item(
                name: _nameController.text.trim(),
                tag: _tag,
                price: double.tryParse(_priceController.text.trim()) ?? 0.0,
                notes: _notesController.text.trim(),
                imagePath: null,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
} 