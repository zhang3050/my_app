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
  late Box<PasswordItem> _box; // Hive盒子，存储所有密码项

  @override
  void initState() {
    super.initState();
    _box = Hive.box<PasswordItem>('passwords'); // 获取密码本数据盒子
  }

  /// 添加或编辑密码项，弹窗输入
  void _addOrEditPassword({PasswordItem? item, int? index}) async {
    final result = await showDialog<PasswordItem>(
      context: context,
      builder: (context) => PasswordEditDialog(item: item),
    );
    if (result != null) {
      if (item == null) {
        await _box.add(result); // 新增
      } else if (index != null) {
        await _box.putAt(index, result); // 编辑
      }
      setState(() {});
    }
  }

  /// 删除密码项，长按卡片触发
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
              padding: EdgeInsets.all(() {
                try { return Hive.box('main_sort').get('password_pad') as double? ?? 16; } catch (_) { return 16.0; }
              }()),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (() {
                  try { return Hive.box('main_sort').get('password_col') as int? ?? 2; } catch (_) { return 2; }
                })(),
                crossAxisSpacing: (() {
                  try { return Hive.box('main_sort').get('password_hgap') as double? ?? 16; } catch (_) { return 16.0; }
                })(),
                mainAxisSpacing: (() {
                  try { return Hive.box('main_sort').get('password_vgap') as double? ?? 16; } catch (_) { return 16.0; }
                })(),
                childAspectRatio: (() {
                  try { return Hive.box('main_sort').get('password_ratio') as double? ?? 1.2; } catch (_) { return 1.2; }
                })(),
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index)!;
                return GestureDetector(
                  onTap: () => _addOrEditPassword(item: item, index: index), // 点击编辑
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA5D6F9), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFA5D6F9).withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Color(0xFFA5D6F9).withOpacity(0.18), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFA5D6F9),
                                ),
                                child: const Icon(Icons.lock, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3d246c)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
          tooltip: '添加密码',
          child: const Icon(Icons.add),
        ),
      );
    } catch (e, s) {
      // 捕获异常并写入日志
      LogService.addError('密码本页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }
}

/// 密码编辑弹窗，支持新增和编辑
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA5D6F9), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFA5D6F9).withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.item == null ? '添加密码' : '编辑密码', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3d246c))),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: '账号', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '密码', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: '备注', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFa6c1ee),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
} 