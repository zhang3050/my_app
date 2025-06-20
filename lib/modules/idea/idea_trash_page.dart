import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'idea_item.dart';

class IdeaTrashPage extends StatelessWidget {
  const IdeaTrashPage({super.key});

  void _restoreIdea(BuildContext context, IdeaItem item) async {
    item.isDeleted = false;
    item.deletedAt = null;
    await item.save();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已恢复创意')));
  }

  void _deleteForever(BuildContext context, Box<IdeaItem> box, int index) async {
    await box.deleteAt(index);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已彻底删除')));
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<IdeaItem>('ideas');
    final now = DateTime.now();
    final List<IdeaItem> trash = [for (int i = 0; i < box.length; i++) box.getAt(i)!]
        .where((e) => e.isDeleted && e.deletedAt != null && now.difference(e.deletedAt!).inDays < 7)
        .toList();
    trash.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: trash.isEmpty
          ? const Center(child: Text('回收站为空'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: trash.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = trash[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash),
                              tooltip: '恢复',
                              onPressed: () => _restoreIdea(context, item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever),
                              tooltip: '彻底删除',
                              onPressed: () => _deleteForever(context, box, index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: item.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '删除于: ${item.deletedAt!.year}-${item.deletedAt!.month.toString().padLeft(2, '0')}-${item.deletedAt!.day.toString().padLeft(2, '0')} ${item.deletedAt!.hour.toString().padLeft(2, '0')}:${item.deletedAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 