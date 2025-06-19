import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'password_item.dart';

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
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<PasswordItem> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('暂无密码，点击右下角添加', style: TextStyle(fontSize: 18)));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final item = box.getAt(index)!;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.username),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditPassword(item: item, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePassword(index),
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(item.title),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('账号：${item.username}'),
                            const SizedBox(height: 8),
                            Text('密码：${item.password}'),
                            const SizedBox(height: 8),
                            Text('备注：${item.notes}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditPassword(),
        tooltip: '添加密码',
        child: const Icon(Icons.add),
      ),
    );
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