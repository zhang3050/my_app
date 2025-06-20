import 'package:hive/hive.dart';
part 'idea_item.g.dart';

@HiveType(typeId: 31)
class IdeaItem extends HiveObject {
  @HiveField(0)
  String content;
  @HiveField(1)
  List<String> tags;
  @HiveField(2)
  DateTime createdAt;
  @HiveField(3)
  bool isStar;
  @HiveField(4)
  bool isArchived;
  @HiveField(5)
  bool isDeleted;
  @HiveField(6)
  DateTime? deletedAt;
  @HiveField(7)
  String title;

  IdeaItem({
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.isStar = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
  });
} 