import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'checkin_item.dart';
import '../../modules/log/log_service.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  late Box<CheckinItem> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<CheckinItem>('checkins');
  }

  void _addOrEditCheckin({CheckinItem? item, int? index}) async {
    final result = await showDialog<CheckinItem>(
      context: context,
      builder: (context) => CheckinEditDialog(item: item),
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

  void _deleteCheckin(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  void _doCheckin(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!item.history.contains(today)) {
      item.history.add(today);
      await item.save();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (context, Box<CheckinItem> box, _) {
            if (box.isEmpty) {
              return const Center(child: Text('暂无打卡项目，点击右下角添加', style: TextStyle(fontSize: 18)));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index)!;
                final today = DateTime.now().toIso8601String().substring(0, 10);
                final checked = item.history.contains(today);
                return GestureDetector(
                  onTap: () => _addOrEditCheckin(item: item, index: index),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('删除打卡'),
                        content: Text('确定要删除"${item.title}"吗？'),
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
                    if (confirm == true) _deleteCheckin(index);
                  },
                  child: Card(
                    color: checked ? Colors.green[50] : Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  checked ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: checked ? Colors.green : Colors.grey,
                                  size: 32,
                                ),
                                onPressed: checked ? null : () => _doCheckin(index),
                                tooltip: checked ? '今日已打卡' : '打卡',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('类型: ${_typeText(item.type)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Text('已打卡: ${item.history.length}天', style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          onPressed: () => _addOrEditCheckin(),
          child: const Icon(Icons.add),
          tooltip: '添加打卡',
        ),
      );
    } catch (e, s) {
      LogService.addError('打卡页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }

  String _typeText(String type) {
    switch (type) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      default:
        return type;
    }
  }
}

class CheckinEditDialog extends StatefulWidget {
  final CheckinItem? item;
  const CheckinEditDialog({super.key, this.item});

  @override
  State<CheckinEditDialog> createState() => _CheckinEditDialogState();
}

class _CheckinEditDialogState extends State<CheckinEditDialog> {
  late TextEditingController _titleController;
  String _type = 'daily';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _type = widget.item?.type ?? 'daily';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '添加打卡' : '编辑打卡'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '打卡内容'),
            ),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'daily'),
              decoration: const InputDecoration(labelText: '打卡类型'),
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
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              CheckinItem(
                title: _titleController.text.trim(),
                type: _type,
                history: widget.item?.history ?? [],
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
} 