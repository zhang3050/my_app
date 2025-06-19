import 'package:hive/hive.dart';
part 'item.g.dart';

@HiveType(typeId: 2)
class Item extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String tag;
  @HiveField(2)
  double price;
  @HiveField(3)
  String notes;
  @HiveField(4)
  String? imagePath;

  Item({
    required this.name,
    required this.tag,
    required this.price,
    required this.notes,
    this.imagePath,
  });
} 