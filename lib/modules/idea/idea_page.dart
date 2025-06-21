import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'idea_item.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  final List<String> _preTags = ['全部', '产品', 'UI', '营销', '内容', '技术', '办公', '生活', '创意'];
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

  // 头像文字
  String getAvatarText(String name) {
    if (name.isEmpty) return '';
    return name.length == 1 ? name : name.substring(0, 2);
  }
  // 头像颜色
  Color getAvatarColor(String name) {
    final colors = [
      Color(0xFF5C6BC0), Color(0xFF42A5F5), Color(0xFF26A69A),
      Color(0xFF66BB6A), Color(0xFFFFB74D), Color(0xFFBA68C8),
      Color(0xFFEF5350), Color(0xFF8D6E63), Color(0xFF789262),
      Color(0xFFB2B2B2)
    ];
    int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [for (int i = 0; i < _box.length; i++) _box.getAt(i)!];
    final showItems = _search.isEmpty
        ? (_filterTag == '全部' ? allItems : allItems.where((item) => item.tags.contains(_filterTag)).toList())
        : allItems.where((item) {
            final q = _search.toLowerCase();
            return item.title.toLowerCase().contains(q) ||
                item.tags.any((t) => t.toLowerCase().contains(q)) ||
                item.content.toLowerCase().contains(q);
          }).toList();
    // 假数据统计
    final total = allItems.length;
    final week = allItems.where((item) {
      final now = DateTime.now();
      final date = item.createdAt;
      return now.difference(date).inDays <= 7;
    }).length;
    final todo = allItems.where((item) => item.tags.contains('待实施')).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F7),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Color(0xFF5C6BC0)),
                      hintText: '搜索创意、关键词或标签...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
              ),
              // 统计区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatCard(total.toString(), '全部创意'),
                    const SizedBox(width: 12),
                    _buildStatCard(week.toString(), '本周新增'),
                  ],
                ),
              ),
              // 标签筛选区
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tags.map((tag) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: _filterTag == tag,
                        onSelected: (_) => setState(() => _filterTag = tag),
                        selectedColor: const Color(0xFF5C6BC0),
                        backgroundColor: const Color(0xFFF3F3F7),
                        labelStyle: TextStyle(color: _filterTag == tag ? Colors.white : Colors.black87),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              // 创意列表
              Expanded(
                child: showItems.isEmpty
                    ? const Center(child: Text('暂无创意，点击右下角"+"添加', style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        itemCount: showItems.length,
                        itemBuilder: (context, index) {
                          final item = showItems[index];
                          return GestureDetector(
                            onTap: () => _addOrEditIdea(item: item, index: allItems.indexOf(item)),
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('删除创意'),
                                  content: const Text('确定要删除该创意吗？'),
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
                              if (confirm == true) _deleteIdea(allItems.indexOf(item));
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // 左侧头像
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: getAvatarColor(item.title),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        getAvatarText(item.title),
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // 右侧内容
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22223B))),
                                          const SizedBox(height: 4),
                                          Text('${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                          const SizedBox(height: 4),
                                          Text(item.content, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditIdea(),
        backgroundColor: const Color(0xFF5C6BC0),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F9FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF22223B))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF7B8FA1))),
          ],
        ),
      ),
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
  late TextEditingController _titleController;
  String _tag = '';
  late DateTime _date;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.item?.content ?? '');
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _tag = widget.item?.tags.isNotEmpty == true ? widget.item!.tags.first : (widget.tags.isNotEmpty ? widget.tags.first : '');
    _date = widget.item?.createdAt ?? DateTime.now();
    // 可选：置顶功能
    // _isPinned = widget.item?.isPinned ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      IdeaItem(
        title: _titleController.text.trim().isEmpty ? '无标题' : _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: [_tag],
        createdAt: _date,
        isStar: widget.item?.isStar ?? false,
        isArchived: widget.item?.isArchived ?? false,
        isDeleted: widget.item?.isDeleted ?? false,
        deletedAt: widget.item?.deletedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: DropdownButton<String>(
          value: _tag,
          underline: const SizedBox(),
          items: widget.tags.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _tag = v ?? _tag),
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.push_pin_outlined, color: Colors.black54), onPressed: () {/*置顶功能*/}),
          IconButton(icon: const Icon(Icons.share, color: Colors.black54), onPressed: () {/*分享功能*/}),
          TextButton(
            onPressed: _onSave,
            child: const Text('保存', style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Text(
              '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')} ${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ),
          // 标题输入
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            decoration: const InputDecoration(
              hintText: '无标题',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            maxLines: 1,
          ),
          Divider(height: 1, thickness: 1, color: Color(0xFFF3F3F7)),
          // 内容输入
          Expanded(
            child: TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: '在这里输入内容',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              cursorColor: Color(0xFF5C6BC0),
            ),
          ),
        ],
      ),
    );
  }
}