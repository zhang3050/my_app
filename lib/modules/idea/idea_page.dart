import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'idea_item.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class IdeaPage extends StatefulWidget {
  const IdeaPage({super.key});
  @override
  State<IdeaPage> createState() => _IdeaPageState();
}

enum IdeaViewType { all, archive, trash }

class _IdeaPageState extends State<IdeaPage> {
  late Box<IdeaItem> _box;
  String _search = '';
  String _filterTag = '全部';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final List<String> _preTags = ['#产品灵感', '#技术方案', '#生活妙招', '#艺术创作'];
  List<String> _tags = [];
  int _starLimit = 5;
  IdeaViewType _viewType = IdeaViewType.all;
  late int col;
  late double ratio, hgap, vgap, pad;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<IdeaItem>('ideas');
    _tags = _preTags;
    final box = Hive.box('main_sort');
    col = box.get('idea_col') as int? ?? 2;
    ratio = box.get('idea_ratio') as double? ?? 1.2;
    hgap = box.get('idea_hgap') as double? ?? 28;
    vgap = box.get('idea_vgap') as double? ?? 32;
    pad = box.get('idea_pad') as double? ?? 20;
    box.watch().listen((_) {
      if (!mounted) return;
      setState(() {
        col = box.get('idea_col') as int? ?? 2;
        ratio = box.get('idea_ratio') as double? ?? 1.2;
        hgap = box.get('idea_hgap') as double? ?? 28;
        vgap = box.get('idea_vgap') as double? ?? 32;
        pad = box.get('idea_pad') as double? ?? 20;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addOrEditIdea({IdeaItem? item, int? index}) async {
    final result = await Navigator.push<IdeaItem>(
      context,
      MaterialPageRoute(
        builder: (context) => IdeaEditPage(
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
      ),
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

  void _deleteIdea(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    item.isDeleted = true;
    item.deletedAt = DateTime.now();
    await item.save();
    setState(() {});
  }

  void _archiveIdea(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    item.isArchived = true;
    await item.save();
    setState(() {});
  }

  void _unarchiveIdea(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    item.isArchived = false;
    await item.save();
    setState(() {});
  }

  void _restoreIdea(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    item.isDeleted = false;
    item.deletedAt = null;
    await item.save();
    setState(() {});
  }

  void _deleteForever(int index) async {
    await _box.deleteAt(index);
    setState(() {});
  }

  void _toggleStar(int index) async {
    final item = _box.getAt(index);
    if (item == null) return;
    if (!item.isStar && _box.values.where((e) => e.isStar && !e.isDeleted && !e.isArchived).length >= _starLimit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('最多只能星标5个创意')));
      return;
    }
    item.isStar = !item.isStar;
    await item.save();
    setState(() {});
  }

  void _tryAddTag() {
    final input = _tagInputController.text.trim();
    if (input.isNotEmpty && !_tags.contains(input)) {
      setState(() {
        _tags.add(input);
        _tagInputController.clear();
      });
    } else if (input.isNotEmpty && _tags.contains(input)) {
      _tagInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 顶部标签栏和搜索框
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 2),
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
                          child: GestureDetector(
                            onLongPress: () async {
                              // 统计该标签下的创意数量
                              final tagCount = _box.values.where((e) => e.tags.contains(tag)).length;
                              if (tagCount == 0) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('删除标签'),
                                    content: Text('确定要删除标签"${tag}"吗？'),
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
                                  setState(() {
                                    _tags.remove(tag);
                                    if (_filterTag == tag) _filterTag = '全部';
                                  });
                                }
                              } else {
                                String? targetTag;
                                final otherTags = _tags.where((t) => t != tag).toList();
                                final confirm = await showDialog<String?>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('标签下有内容'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('该标签下有 $tagCount 个创意。'),
                                        const SizedBox(height: 12),
                                        if (otherTags.isNotEmpty)
                                          DropdownButtonFormField<String>(
                                            value: otherTags.first,
                                            items: otherTags.map((t) => DropdownMenuItem(value: t, child: Text('转移到 $t'))).toList(),
                                            onChanged: (v) => targetTag = v,
                                            decoration: const InputDecoration(labelText: '选择目标标签'),
                                          ),
                                        const SizedBox(height: 8),
                                        const Text('或选择全部移除标签', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, null),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, ''),
                                        child: const Text('全部移除', style: TextStyle(color: Colors.red)),
                                      ),
                                      if (otherTags.isNotEmpty)
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, targetTag ?? otherTags.first),
                                          child: const Text('转移'),
                                        ),
                                    ],
                                  ),
                                );
                                if (confirm != null) {
                                  setState(() {
                                    _tags.remove(tag);
                                    if (_filterTag == tag) _filterTag = '全部';
                                  });
                                  for (var i = 0; i < _box.length; i++) {
                                    final item = _box.getAt(i);
                                    if (item != null && item.tags.contains(tag)) {
                                      item.tags.remove(tag);
                                      if (confirm.isNotEmpty) {
                                        // 转移到目标标签
                                        if (!item.tags.contains(confirm)) item.tags.add(confirm);
                                      }
                                      item.save();
                                    }
                                  }
                                }
                              }
                            },
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: _filterTag == tag,
                              onSelected: (_) => setState(() => _filterTag = tag),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(color: _filterTag == tag ? Colors.white : Colors.black87),
                            ),
                          ),
                        )),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ElevatedButton(
                            onPressed: _tryAddTag,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB2E5C8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ),
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
                      hintText: '搜索创意/标签/日期',
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
              ],
            ),
            // 内容区
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, Box<IdeaItem> box, _) {
                  final List<IdeaItem> allItems = [for (int i = 0; i < box.length; i++) box.getAt(i)!];
                  List<IdeaItem> items;
                  if (_viewType == IdeaViewType.all) {
                    items = allItems.where((e) => !e.isDeleted && !e.isArchived).toList();
                  } else {
                    final now = DateTime.now();
                    items = allItems.where((e) => e.isDeleted && e.deletedAt != null && now.difference(e.deletedAt!).inDays < 7).toList();
                  }
                  // 标签筛选
                  final List<IdeaItem> filtered = _filterTag == '全部' ? items : items.where((item) => item.tags.contains(_filterTag)).toList();
                  // 搜索
                  final List<IdeaItem> showItems = _search.isEmpty
                      ? filtered
                      : filtered.where((item) {
                          final q = _search.toLowerCase();
                          return item.content.toLowerCase().contains(q) ||
                              item.tags.any((t) => t.toLowerCase().contains(q)) ||
                              item.createdAt.toString().contains(q);
                        }).toList();
                  // 时间倒序，星标置顶
                  showItems.sort((a, b) {
                    if (a.isStar != b.isStar) return b.isStar ? 1 : -1;
                    return b.createdAt.compareTo(a.createdAt);
                  });
                  if (showItems.isEmpty) {
                    if (_viewType == IdeaViewType.all) {
                      return const Center(child: Text('暂无创意，点击右下角"+"添加', style: TextStyle(fontSize: 18)));
                    } else {
                      return const SizedBox.shrink();
                    }
                  }
                  return Padding(
                    padding: EdgeInsets.all(pad),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: col,
                        crossAxisSpacing: hgap,
                        mainAxisSpacing: vgap,
                        childAspectRatio: ratio,
                      ),
                      itemCount: showItems.length,
                      itemBuilder: (context, index) {
                        final item = showItems[index];
                        return Dismissible(
                          key: ValueKey(item.key),
                          direction: _viewType == IdeaViewType.all ? DismissDirection.startToEnd : DismissDirection.none,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            color: Colors.blueGrey[100],
                            child: const Icon(Icons.archive, color: Colors.blueGrey, size: 32),
                          ),
                          onDismissed: _viewType == IdeaViewType.all ? (_) => _archiveIdea(allItems.indexOf(item)) : null,
                          child: GestureDetector(
                            onTap: () => _addOrEditIdea(item: item, index: allItems.indexOf(item)),
                            onLongPress: () {
                              if (_viewType == IdeaViewType.all) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('删除创意'),
                                    content: const Text('确定要删除该创意吗？删除后可在回收站找回。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteIdea(allItems.indexOf(item));
                                          Navigator.pop(context);
                                        },
                                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (_viewType == IdeaViewType.trash) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('彻底删除'),
                                    content: const Text('确定要彻底删除该创意吗？此操作不可恢复。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteForever(allItems.indexOf(item));
                                          Navigator.pop(context);
                                        },
                                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Spacer(),
                                        if (item.isStar)
                                          const Icon(Icons.star, color: Colors.amber, size: 22),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: item.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // 右下角添加按钮
        if (_viewType == IdeaViewType.all)
          Positioned(
            right: 24,
            bottom: 32,
            child: FloatingActionButton(
              onPressed: () => _addOrEditIdea(),
              child: const Icon(Icons.add),
              tooltip: '添加创意',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
      ],
    );
  }
}

class IdeaEditPage extends StatefulWidget {
  final IdeaItem? item;
  final List<String> tags;
  final void Function(String newTag)? onAddTag;
  const IdeaEditPage({this.item, required this.tags, this.onAddTag});
  @override
  State<IdeaEditPage> createState() => _IdeaEditPageState();
}

class _IdeaEditPageState extends State<IdeaEditPage> {
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late TextEditingController _titleController;
  String _tag = '';
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.item?.content ?? '');
    _tagInputController = TextEditingController();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _tag = widget.item?.tags.isNotEmpty == true ? widget.item!.tags.first : (widget.tags.isNotEmpty ? widget.tags.first : '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagInputController.dispose();
    _titleController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? '添加创意' : '编辑创意'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.remove_red_eye),
            tooltip: _showPreview ? '编辑' : '预览',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题（必填）', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
              maxLength: 30,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.tags.map((t) => ChoiceChip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                selected: _tag == t,
                onSelected: (_) => setState(() => _tag = t),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(color: _tag == t ? Colors.white : Colors.black87, fontSize: 12),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(
                      hintText: '新标签',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    ),
                    onSubmitted: (_) => _tryAddTag(),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _tryAddTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2E5C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(32, 32),
                  ),
                  child: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // 内容编辑框更大
            !_showPreview
                ? TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: '创意内容（支持Markdown）', filled: true, fillColor: Colors.white70, border: OutlineInputBorder()),
                    minLines: 16,
                    maxLines: null,
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: MarkdownBody(
                        data: _contentController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        softLineBreak: true,
                        shrinkWrap: true,
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
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
                    if (_titleController.text.trim().isEmpty) return;
                    if (_contentController.text.trim().isEmpty) return;
                    Navigator.pop(
                      context,
                      IdeaItem(
                        title: _titleController.text.trim(),
                        content: _contentController.text.trim(),
                        tags: [_tag],
                        createdAt: widget.item?.createdAt ?? DateTime.now(),
                        isStar: widget.item?.isStar ?? false,
                        isArchived: widget.item?.isArchived ?? false,
                        isDeleted: widget.item?.isDeleted ?? false,
                        deletedAt: widget.item?.deletedAt,
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