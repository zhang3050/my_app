import 'idea_item.dart';
import 'package:hive/hive.dart';

class IdeaExport {
  static Future<String> exportToTxt() async {
    final box = Hive.box<IdeaItem>('ideas');
    final items = box.values.where((e) => !e.isDeleted && !e.isArchived).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final buffer = StringBuffer();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('【${i + 1}】${item.content}');
      buffer.writeln('标签: ${item.tags.join(", ")}');
      buffer.writeln('时间: ${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}');
      buffer.writeln('------------------------------');
    }
    return buffer.toString();
  }
} 