import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'password_item.dart';
import '../../modules/log/log_service.dart';

class PasswordBookPage extends StatefulWidget {
  const PasswordBookPage({super.key});

  @override
  State<PasswordBookPage> createState() => _PasswordBookPageState();
}

class _PasswordBookPageState extends State<PasswordBookPage> {
  late Box<PasswordItem> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<PasswordItem>('passwords');
  }

  void _addOrEditPassword({PasswordItem? item, int? index}) async {
    final result = await showDialog<PasswordItem>(
      context: context,
      builder: (context) => PasswordEditDialog(item: item),
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

  void _deletePassword(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (context, Box<PasswordItem> box, _) {
            if (box.isEmpty) {
              return const Center(child: Text('暂无密码，点击右下角添加', style: TextStyle(fontSize: 18)));
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
                return GestureDetector(
                  onTap: () => _addOrEditPassword(item: item, index: index),
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('删除密码'),
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
                    if (confirm == true) _deletePassword(index);
                  },
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    shadowColor: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Icon(Icons.lock, color: Colors.deepPurple, size: 28),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('账号: ${item.username}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                          const SizedBox(height: 10),
                          Text('备注: ${item.notes}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
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
          onPressed: () => _addOrEditPassword(),
          child: const Icon(Icons.add),
          tooltip: '添加密码',
        ),
      );
    } catch (e, s) {
      LogService.addError('密码本页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }
}

class PasswordEditDialog extends StatefulWidget {
  final PasswordItem? item;
  const PasswordEditDialog({super.key, this.item});

  @override
  State<PasswordEditDialog> createState() => _PasswordEditDialogState();
}

class _PasswordEditDialogState extends State<PasswordEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _usernameController = TextEditingController(text: widget.item?.username ?? '');
    _passwordController = TextEditingController(text: widget.item?.password ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '添加密码' : '编辑密码'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: '账号'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
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
            if (_titleController.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              PasswordItem(
                title: _titleController.text.trim(),
                username: _usernameController.text.trim(),
                password: _passwordController.text.trim(),
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
} 