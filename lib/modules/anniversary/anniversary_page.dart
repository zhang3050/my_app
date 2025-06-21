import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'anniversary_item.dart';
import 'package:lunar/lunar.dart';

class AnniversaryPage extends StatefulWidget {
  const AnniversaryPage({super.key});

  @override
  State<AnniversaryPage> createState() => _AnniversaryPageState();
}

class _AnniversaryPageState extends State<AnniversaryPage> {
  late Box<AnniversaryItem> _box;
  List<String> _tags = ['家庭', '朋友', '节日', '纪念', '其他'];
  String _search = '';
  String _filterTag = '全部';
  final TextEditingController _searchController = TextEditingController();
  late int col;
  late double ratio, hgap, vgap, pad;
  String? _tagToDelete;
  bool _tagDeleteMode = false;
  String? _tagDeleteTarget;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<AnniversaryItem>('anniversaries');
    final box = Hive.box('main_sort');
    col = box.get('anniversary_col') as int? ?? 2;
    ratio = box.get('anniversary_ratio') as double? ?? 1.2;
    hgap = box.get('anniversary_hgap') as double? ?? 28;
    vgap = box.get('anniversary_vgap') as double? ?? 32;
    pad = box.get('anniversary_pad') as double? ?? 20;
    box.watch().listen((_) {
      if (!mounted) return;
      setState(() {
        col = box.get('anniversary_col') as int? ?? 2;
        ratio = box.get('anniversary_ratio') as double? ?? 1.2;
        hgap = box.get('anniversary_hgap') as double? ?? 28;
        vgap = box.get('anniversary_vgap') as double? ?? 32;
        pad = box.get('anniversary_pad') as double? ?? 20;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addOrEditAnniversary({AnniversaryItem? item, int? index}) async {
    final result = await showDialog<AnniversaryItem>(
      context: context,
      builder: (context) => _AnniversaryEditDialog(
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
        await _box.add(result);
        // TODO: 日志同步
      } else if (index != null) {
        await _box.putAt(index, result);
        // TODO: 日志同步
      }
      setState(() {});
    }
  }

  void _deleteAnniversary(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除纪念日'),
        content: const Text('确定要删除该纪念日吗？'),
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
    if (confirm == true) {
      await _box.deleteAt(index);
      setState(() {});
    }
  }

  int _daysToAnniversary(AnniversaryItem item) {
    final now = DateTime.now();
    DateTime next;
    if (item.isLunar) {
      // 农历转公历
      final lunar = Lunar.fromYmd(item.date.year, item.date.month, item.date.day);
      final solar = lunar.getSolar();
      DateTime solarDate = DateTime(now.year, solar.getMonth(), solar.getDay());
      if (solarDate.isBefore(now) && item.repeatYearly) {
        // 下一年
        final nextLunar = Lunar.fromYmd(now.year + 1, item.date.month, item.date.day);
        final nextSolar = nextLunar.getSolar();
        solarDate = DateTime(now.year + 1, nextSolar.getMonth(), nextSolar.getDay());
      }
      next = solarDate;
      // 判断当天农历是否为纪念日
      final nowLunar = Lunar.fromDate(now);
      if (nowLunar.getMonth() == item.date.month && nowLunar.getDay() == item.date.day) {
        return 0;
      }
    } else {
      next = DateTime(now.year, item.date.month, item.date.day);
      if (next.isBefore(now) && item.repeatYearly) {
        next = DateTime(now.year + 1, item.date.month, item.date.day);
      }
      if (now.month == item.date.month && now.day == item.date.day) {
        return 0;
      }
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_tagDeleteMode) setState(() {
          _tagDeleteMode = false;
          _tagDeleteTarget = null;
        });
      },
      behavior: HitTestBehavior.translucent,
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
                      // “全部”标签不能被删除，只能筛选
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('全部'),
                          selected: _filterTag == '全部',
                          onSelected: (_) => setState(() => _filterTag = '全部'),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                          labelStyle: TextStyle(color: _filterTag == '全部' ? Colors.white : Colors.black87),
                        ),
                      ),
                      ..._tags.where((tag) => tag != '全部').map((tag) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _TagChip(
                          tag: tag,
                          selected: _filterTag == tag,
                          deleteMode: _tagDeleteMode && _tagDeleteTarget == tag,
                          onSelect: () {
                            if (_tagDeleteMode) {
                              setState(() {
                                _tagDeleteMode = false;
                                _tagDeleteTarget = null;
                              });
                            } else {
                              setState(() => _filterTag = tag);
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _tagDeleteMode = true;
                              _tagDeleteTarget = tag;
                            });
                          },
                          onDelete: () async {
                            final itemsWithTag = _box.values.where((e) => e.tag == tag).toList();
                            if (itemsWithTag.isEmpty) {
                              setState(() {
                                _tags.remove(tag);
                                if (_filterTag == tag) _filterTag = '全部';
                                _tagDeleteMode = false;
                                _tagDeleteTarget = null;
                              });
                              return;
                            }
                            final otherTags = _tags.where((t) => t != tag && t != '全部').toList();
                            String? selectedTag = otherTags.isNotEmpty ? otherTags.first : null;
                            final res = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('删除标签 "$tag"'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('该标签下有纪念日，是否将这些纪念日转移到其他标签？'),
                                      const SizedBox(height: 12),
                                      if (otherTags.isNotEmpty)
                                        DropdownButtonFormField<String>(
                                          value: selectedTag,
                                          items: otherTags.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, null),
                                      child: const Text('取消操作'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (res == null) return;
                            bool move = false;
                            String? newTag;
                            if (res['move'] == true && res['newTag'] != null) {
                              move = true;
                              newTag = res['newTag'];
                            }
                            if (move && newTag != null) {
                              for (final item in itemsWithTag) {
                                item.tag = newTag;
                                await item.save();
                              }
                            } else if (!move) {
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
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '搜索纪念日名称、备注、标签...（支持模糊搜索）',
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
                builder: (context, Box<AnniversaryItem> box, _) {
                  final List<AnniversaryItem> allItems = [for (int i = 0; i < box.length; i++) box.getAt(i)!];
                  // 标签筛选
                  final List<AnniversaryItem> filtered = _filterTag == '全部' ? allItems : allItems.where((item) => item.tag == _filterTag).toList();
                  // 搜索
                  final List<AnniversaryItem> items = _search.isEmpty
                      ? filtered
                      : filtered.where((item) {
                          final q = _search.toLowerCase();
                          return item.name.toLowerCase().contains(q) ||
                              item.notes.toLowerCase().contains(q) ||
                              item.tag.toLowerCase().contains(q);
                        }).toList();
                  // 按倒计时排序
                  items.sort((a, b) => _daysToAnniversary(a).compareTo(_daysToAnniversary(b)));
                  if (items.isEmpty) {
                    return const Center(child: Text('暂无匹配纪念日，换个关键词试试', style: TextStyle(fontSize: 18)));
                  }
                  return GridView.builder(
                    padding: EdgeInsets.all(pad),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: col,
                      crossAxisSpacing: hgap,
                      mainAxisSpacing: vgap,
                      childAspectRatio: ratio,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final days = _daysToAnniversary(item);
                      final isSoon = days >= 0 && days <= 7;
                      return GestureDetector(
                        onTap: () => _addOrEditAnniversary(item: item, index: allItems.indexOf(item)),
                        onLongPress: () => _deleteAnniversary(allItems.indexOf(item)),
                        child: Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(item.isLunar ? Icons.brightness_2 : Icons.wb_sunny, size: 18, color: item.isLunar ? Colors.deepOrange : Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(item.isLunar ? '农历' : '公历'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 名称自动折叠
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('日期: ${item.date.year}-${item.date.month}-${item.date.day}', style: const TextStyle(fontSize: 13)),
                                // 备注自动折叠
                                if (item.notes.isNotEmpty)
                                  Text(
                                    '备注: ${item.notes}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const Spacer(),
                                // 卡片底部内容防溢出
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Icon(Icons.timer, size: 18, color: isSoon ? Colors.red : Colors.deepOrange),
                                    Text(
                                      days == 0 ? '今天' : days < 0 ? '已过' : '距离纪念日: $days 天',
                                      style: TextStyle(
                                        color: isSoon ? Colors.red : Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Chip(
                                      label: Text(
                                        item.tag,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
          onPressed: () => _addOrEditAnniversary(),
          child: const Icon(Icons.add),
          tooltip: '添加纪念日',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }
}

class _AnniversaryEditDialog extends StatefulWidget {
  final AnniversaryItem? item;
  final List<String> tags;
  final void Function(String newTag)? onAddTag;
  const _AnniversaryEditDialog({this.item, required this.tags, this.onAddTag});

  @override
  State<_AnniversaryEditDialog> createState() => _AnniversaryEditDialogState();
}

class _AnniversaryEditDialogState extends State<_AnniversaryEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _tagInputController;
  String _tag = '';
  DateTime _date = DateTime.now();
  bool _isLunar = false;
  bool _repeatYearly = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _tagInputController = TextEditingController();
    _tag = widget.item?.tag ?? (widget.tags.isNotEmpty ? widget.tags.first : '');
    _date = widget.item?.date ?? DateTime.now();
    _isLunar = widget.item?.isLunar ?? false;
    _repeatYearly = widget.item?.repeatYearly ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            colors: [Color(0xFFF5F6FA), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.10),
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
              Text(widget.item == null ? '添加纪念日' : '编辑纪念日', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3d246c))),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '纪念日名称', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
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
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (_isLunar) {
                          // 农历选择弹窗
                          final picked = await showDialog<DateTime>(
                            context: context,
                            builder: (context) => _LunarDatePickerDialog(initDate: _date),
                          );
                          if (picked != null) setState(() => _date = picked);
                        } else {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(1900, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.deepPurple,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _date = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: '日期', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(_isLunar
                                ? '农历 ${_date.year}-${_date.month}-${_date.day}'
                                : '${_date.year}-${_date.month}-${_date.day}',
                              style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text('农历'),
                      Switch(
                        value: _isLunar,
                        onChanged: (v) => setState(() => _isLunar = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _repeatYearly,
                    onChanged: (v) => setState(() => _repeatYearly = v ?? true),
                  ),
                  const Text('每年重复'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '备注', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
                maxLines: 2,
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
                        AnniversaryItem(
                          name: _nameController.text.trim(),
                          date: _date,
                          isLunar: _isLunar,
                          notes: _notesController.text.trim(),
                          tag: _tag,
                          repeatYearly: _repeatYearly,
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

class _LunarDatePickerDialog extends StatefulWidget {
  final DateTime initDate;
  const _LunarDatePickerDialog({required this.initDate});
  @override
  State<_LunarDatePickerDialog> createState() => _LunarDatePickerDialogState();
}

class _LunarDatePickerDialogState extends State<_LunarDatePickerDialog> {
  late int year;
  late int month;
  late int day;
  @override
  void initState() {
    super.initState();
    year = widget.initDate.year;
    month = widget.initDate.month;
    day = widget.initDate.day;
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择农历日期'),
      content: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              value: year,
              items: [for (int y = 1900; y <= 2100; y++) DropdownMenuItem(value: y, child: Text('$y年'))],
              onChanged: (v) => setState(() => year = v!),
            ),
          ),
          Expanded(
            child: DropdownButton<int>(
              value: month,
              items: [for (int m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('$m月'))],
              onChanged: (v) => setState(() => month = v!),
            ),
          ),
          Expanded(
            child: DropdownButton<int>(
              value: day,
              items: [for (int d = 1; d <= 30; d++) DropdownMenuItem(value: d, child: Text('$d日'))],
              onChanged: (v) => setState(() => day = v!),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, DateTime(year, month, day));
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

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