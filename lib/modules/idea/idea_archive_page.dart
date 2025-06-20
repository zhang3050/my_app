import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'idea_item.dart';

class IdeaArchivePage extends StatelessWidget {
  const IdeaArchivePage({super.key});

  void _unarchiveIdea(BuildContext context, IdeaItem item) async {
    item.isArchived = false;
    await item.save();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消归档')));
  }

  void _shareIdea(IdeaItem item) {
    // TODO: 实现分享功能
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<IdeaItem>('ideas');
    final List<IdeaItem> archived = [for (int i = 0; i < box.length; i++) box.getAt(i)!]
        .where((e) => e.isArchived && !e.isDeleted)
        .toList();
    archived.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: const Text('归档库')),
      body: archived.isEmpty
          ? const Center(child: Text('暂无归档创意'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: archived.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = archived[index];
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
                            const Icon(Icons.archive, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.unarchive),
                              tooltip: '取消归档',
                              onPressed: () => _unarchiveIdea(context, item),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'share') _shareIdea(item);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'share', child: Text('分享')),
                              ],
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
                          '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
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