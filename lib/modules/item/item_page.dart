import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'item.dart';
import '../../modules/log/log_service.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late Box<Item> _box; // Hive盒子，存储所有物品项
  List<String> _tags = ['家居', '娱乐', '办公', '学习', '运动', '其他']; // 预设标签
  String _search = '';
  String _filterTag = '全部';
  bool _tagDeleteMode = false;
  String? _tagDeleteTarget;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Item>('items'); // 获取物品数据盒子
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 添加或编辑物品项，弹窗输入
  void _addOrEditItem({Item? item, int? index}) async {
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemEditDialog(
        item: item,
        tags: _tags,
        onAddTag: (newTag) {
          if (!_tags.contains(newTag)) {
            setState(() {
              _tags.add(newTag);
            });
          }
        },
      ),
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

  /// 删除物品项，长按卡片触发
  void _deleteItem(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  /// 价格格式化，保留两位小数
  String _formatPrice(double price) {
    int p = (price * 100).truncate();
    return (p / 100).toStringAsFixed(2);
  }

  /// 删除标签时的处理逻辑
  Future<void> _handleDeleteTag(String tag) async {
    final itemsWithTag = _box.values.where((item) => item.tag == tag).toList();
    if (itemsWithTag.isEmpty) {
      setState(() {
        _tags.remove(tag);
        if (_filterTag == tag) _filterTag = '全部';
        _tagDeleteMode = false;
        _tagDeleteTarget = null;
      });
      return;
    }
    String? newTag;
    bool move = false;
    if (_tags.length > 1) {
      final res = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          String? selectedTag = _tags.firstWhere((t) => t != tag, orElse: () => '');
          return AlertDialog(
            title: Text('删除标签 "$tag"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('该标签下有物品，是否将这些物品转移到其他标签？'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTag,
                  items: _tags.where((t) => t != tag).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => selectedTag = v,
                  decoration: const InputDecoration(labelText: '转移到', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, {'move': false}),
                child: const Text('全部删除'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'move': true, 'newTag': selectedTag}),
                child: const Text('转移'),
              ),
            ],
          );
        },
      );
      if (res != null && res['move'] == true && res['newTag'] != null) {
        move = true;
        newTag = res['newTag'];
      }
    } else {
      // 只剩一个标签，直接删除
      move = false;
    }
    if (move && newTag != null) {
      for (final item in itemsWithTag) {
        item.tag = newTag;
        await item.save();
      }
    } else {
      // 全部删除该标签下物品
      for (final item in itemsWithTag) {
        await item.delete();
      }
    }
    setState(() {
      _tags.remove(tag);
      if (_filterTag == tag) _filterTag = '全部';
      _tagDeleteMode = false;
      _tagDeleteTarget = null;
    });
  }

  void _enterTagDeleteMode(String tag) {
    setState(() {
      _tagDeleteMode = true;
      _tagDeleteTarget = tag;
    });
  }

  void _exitTagDeleteMode() {
    setState(() {
      _tagDeleteMode = false;
      _tagDeleteTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return GestureDetector(
        onTap: () {
          if (_tagDeleteMode) _exitTagDeleteMode();
        },
        child: Scaffold(
          body: Column(
            children: [
              // 标签筛选区
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 2),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('全部'),
                          selected: _filterTag == '全部',
                          onSelected: (_) => setState(() => _filterTag = '全部'),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(color: _filterTag == '全部' ? Colors.white : Colors.black87),
                        ),
                        ..._tags.map((tag) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TagChip(
                            tag: tag,
                            selected: _filterTag == tag,
                            deleteMode: _tagDeleteMode && _tagDeleteTarget == tag,
                            onSelect: () {
                              if (_tagDeleteMode) {
                                _exitTagDeleteMode();
                              } else {
                                setState(() => _filterTag = tag);
                              }
                            },
                            onLongPress: () => _enterTagDeleteMode(tag),
                            onDelete: () async { await _handleDeleteTag(tag); },
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: '搜索物品名称、标签、备注...（支持模糊搜索）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _search = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _box.listenable(),
                  builder: (context, Box<Item> box, _) {
                    final List<Item> allItems = [for (int i = 0; i < box.length; i++) box.getAt(i)!];
                    final List<Item> filtered = _filterTag == '全部' ? allItems : allItems.where((item) => item.tag == _filterTag).toList();
                    final List<Item> items = _search.isEmpty
                        ? filtered
                        : filtered.where((item) {
                            final q = _search.toLowerCase();
                            return item.name.toLowerCase().contains(q) ||
                                item.tag.toLowerCase().contains(q) ||
                                item.notes.toLowerCase().contains(q);
                          }).toList();
                    if (items.isEmpty) {
                      return const Center(child: Text('暂无匹配物品，换个关键词试试', style: TextStyle(fontSize: 18)));
                    }
                    return GridView.builder(
                      padding: EdgeInsets.all(() {
                        try { return Hive.box('main_sort').get('item_pad') as double? ?? 16; } catch (_) { return 16.0; }
                      }()),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: (() {
                          try { return Hive.box('main_sort').get('item_col') as int? ?? 2; } catch (_) { return 2; }
                        })(),
                        crossAxisSpacing: (() {
                          try { return Hive.box('main_sort').get('item_hgap') as double? ?? 16; } catch (_) { return 16.0; }
                        })(),
                        mainAxisSpacing: (() {
                          try { return Hive.box('main_sort').get('item_vgap') as double? ?? 16; } catch (_) { return 16.0; }
                        })(),
                        childAspectRatio: (() {
                          try { return Hive.box('main_sort').get('item_ratio') as double? ?? 0.85; } catch (_) { return 0.85; }
                        })(),
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () => _addOrEditItem(item: item, index: allItems.indexOf(item)), // 点击编辑
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
                            if (confirm == true) _deleteItem(allItems.indexOf(item));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB2E5C8), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFB2E5C8).withOpacity(0.10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(color: Color(0xFFB2E5C8).withOpacity(0.18), width: 1.2),
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
                                          color: Color(0xFFB2E5C8),
                                        ),
                                        child: const Icon(Icons.inventory, color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3d246c)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('标签: ${item.tag}', style: const TextStyle(fontSize: 15, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                  const SizedBox(height: 10),
                                  Text('价格: ¥${_formatPrice(item.price)}', style: const TextStyle(fontSize: 16, color: Colors.deepOrange), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addOrEditItem(),
            tooltip: '添加物品',
            child: const Icon(Icons.add),
          ),
        ),
      );
    } catch (e, s) {
      // 捕获异常并写入日志
      LogService.addError('物品管理页面构建异常: $e\n$s');
      return const Center(child: Text('页面出错，详情见日志'));
    }
  }
}

/// 物品编辑弹窗，支持新增和编辑
class ItemEditDialog extends StatefulWidget {
  final Item? item;
  final List<String> tags;
  final void Function(String newTag)? onAddTag;
  const ItemEditDialog({super.key, this.item, required this.tags, this.onAddTag});

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late TextEditingController _tagInputController;
  String _tag = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _tagInputController = TextEditingController();
    _tag = widget.item?.tag ?? (widget.tags.isNotEmpty ? widget.tags.first : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _tryAddTag() {
    final input = _tagInputController.text.trim();
    if (input.isNotEmpty && !widget.tags.contains(input)) {
      widget.onAddTag?.call(input);
      setState(() {
        _tag = input;
        _tagInputController.clear();
      });
    } else if (input.isNotEmpty && widget.tags.contains(input)) {
      setState(() {
        _tag = input;
        _tagInputController.clear();
      });
    }
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
            colors: [Color(0xFFB2E5C8), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFB2E5C8).withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.item == null ? '添加物品' : '编辑物品', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3d246c))),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '物品名称', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: widget.tags.contains(_tag) ? _tag : (widget.tags.isNotEmpty ? widget.tags.first : ''),
                      items: widget.tags.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tag = v ?? (widget.tags.isNotEmpty ? widget.tags.first : '')),
                      decoration: const InputDecoration(labelText: '标签', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _tagInputController,
                      decoration: const InputDecoration(
                        hintText: '新标签',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                      onSubmitted: (_) => _tryAddTag(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _tryAddTag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2E5C8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '价格', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                      backgroundColor: const Color(0xFF185a9d),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 新增组件：_TagChip
class _TagChip extends StatelessWidget {
  final String tag;
  final bool selected;
  final bool deleteMode;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  const _TagChip({required this.tag, required this.selected, this.deleteMode = false, required this.onSelect, required this.onLongPress, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      onLongPress: onLongPress,
      child: Chip(
        label: Text(tag),
        backgroundColor: deleteMode
            ? Colors.red[400]
            : (selected ? Theme.of(context).colorScheme.primary : Colors.grey[200]),
        labelStyle: TextStyle(color: deleteMode ? Colors.white : (selected ? Colors.white : Colors.black87)),
        deleteIcon: deleteMode ? const Icon(Icons.close, size: 18, color: Colors.white) : null,
        onDeleted: deleteMode ? onDelete : null,
      ),
    );
  }
} 