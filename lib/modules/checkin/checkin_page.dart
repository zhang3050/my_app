import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'checkin_item.dart';
import '../../modules/log/log_service.dart';
import 'dart:async';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  late Box<CheckinItem> _box; // Hive盒子，存储所有打卡项
  Timer? _midnightTimer; // 用于自动重置的定时器
  String _filterType = 'all'; // 当前筛选类型
  final List<Map<String, String>> _typeTabs = [
    {'label': '全部', 'value': 'all'},
    {'label': '每日', 'value': 'daily'},
    {'label': '每周', 'value': 'weekly'},
    {'label': '每月', 'value': 'monthly'},
  ];

  @override
  void initState() {
    super.initState();
    _box = Hive.box<CheckinItem>('checkins'); // 获取打卡数据盒子
    _scheduleMidnightReset(); // 启动自动重置
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  /// 定时器：每天零点自动重置打卡状态
  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () {
      _resetCheckinsForNewDay();
      _scheduleMidnightReset();
    });
  }

  /// 重置所有打卡项的今日状态
  void _resetCheckinsForNewDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (int i = 0; i < _box.length; i++) {
      final item = _box.getAt(i);
      if (item == null) continue;
      // 统计实际打卡天数
      int targetDays = 0;
      switch (item.type) {
        case 'daily':
          targetDays = 1;
          break;
        case 'weekly':
          targetDays = 7;
          break;
        case 'monthly':
          targetDays = 30;
          break;
        default:
          targetDays = 1;
      }
      // 如果已达目标天数，不再重置
      if (item.history.length >= targetDays) continue;
      // 如果今天未打卡，仅刷新UI即可
      if (item.history.contains(today)) {
        // do nothing
      } else {
        // 只需setState触发UI刷新，实际打卡状态由history决定
      }
    }
    setState(() {});
  }

  /// 添加或编辑打卡项，弹窗输入
  void _addOrEditCheckin({CheckinItem? item, int? index}) async {
    final result = await showDialog<CheckinItem>(
      context: context,
      builder: (context) => CheckinEditDialog(item: item),
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

  /// 删除打卡项，长按卡片触发
  void _deleteCheckin(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  /// 切换打卡/取消打卡状态
  void _toggleCheckin(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (item.history.contains(today)) {
      item.history.remove(today);
    } else {
      item.history.add(today);
    }
    await item.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: _typeTabs.map((tab) {
              final selected = _filterType == tab['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filterType = tab['value']!),
                  child: Container(
                    color: selected ? Colors.blue[100] : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(tab['label']!, style: TextStyle(color: selected ? Colors.blue : Colors.black)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (context, Box<CheckinItem> box, _) {
            List<CheckinItem> items = [for (int i = 0; i < box.length; i++) box.getAt(i)!];
            // 标签筛选
            if (_filterType != 'all') {
              items = items.where((e) => e.type == _filterType).toList();
            }
            // 排序：未打卡的在前，已打卡的在后
            final today = DateTime.now().toIso8601String().substring(0, 10);
            items.sort((a, b) {
              final aChecked = a.history.contains(today);
              final bChecked = b.history.contains(today);
              if (aChecked == bChecked) return 0;
              return aChecked ? 1 : -1;
            });
            if (items.isEmpty) {
              return const Center(child: Text('暂无打卡项目，点击右下角添加', style: TextStyle(fontSize: 18)));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final checked = item.history.contains(today);
                return IntrinsicHeight(
                  child: GestureDetector(
                    onTap: () => _addOrEditCheckin(item: item, index: _box.values.toList().indexOf(item)), // 点击编辑
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
                      if (confirm == true) _deleteCheckin(_box.values.toList().indexOf(item));
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      shadowColor: Colors.black12,
                      color: checked
                          ? Colors.grey[300]
                          : Colors.lightBlue[100],
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
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
                                IconButton(
                                  icon: Icon(
                                    checked ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: checked ? Colors.green : Colors.grey,
                                    size: 32,
                                  ),
                                  onPressed: () => _showCheckinDialog(item, _box.values.toList().indexOf(item), checked),
                                  tooltip: checked ? '取消今日打卡/补打卡' : '打卡/补打卡',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('类型: ${_typeText(item.type)}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                            const SizedBox(height: 10),
                            Text('已打卡: ${_getCheckinDays(item)}天', style: const TextStyle(fontSize: 16, color: Colors.deepOrange), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ],
                        ),
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
      // 捕获异常并写入日志
      LogService.addError('打卡页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }

  void _showCheckinDialog(CheckinItem item, int index, bool checked) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (item.type == 'daily') {
      // 每日类型直接切换打卡状态
      if (item.history.contains(today)) {
        item.history.remove(today);
      } else {
        item.history.add(today);
      }
      await item.save();
      setState(() {});
      return;
    }
    final List<String> days = _getMonthDays();
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(checked ? '取消/补打卡' : '打卡/补打卡'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...days.map((d) => ListTile(
                        title: Text(
                          d == today ? '今天' : d,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: item.history.contains(d)
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        onTap: () async {
                          if (item.history.contains(d)) {
                            item.history.remove(d);
                          } else {
                            item.history.add(d);
                          }
                          await item.save();
                          setState(() {});
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e, s) {
      LogService.addError('补打卡弹窗异常: $e\n$s\nitem: ${item.title}, type: ${item.type}');
      debugPrint('补打卡弹窗异常: $e\n$s\nitem: ${item.title}, type: ${item.type}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('补打卡弹窗异常，详情见日志')));
      }
    }
  }

  List<String> _getMonthDays() {
    final now = DateTime.now();
    final days = <String>[];
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    for (int i = 0; i < lastDay.day; i++) {
      final d = firstDay.add(Duration(days: i));
      days.add(d.toIso8601String().substring(0, 10));
    }
    return days;
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

  int _getCheckinDays(CheckinItem item) {
    // 只统计实际打卡天数
    return item.history.length;
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