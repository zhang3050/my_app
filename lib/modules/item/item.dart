import 'package:hive/hive.dart';
part 'item.g.dart';

@HiveType(typeId: 2)
class Item extends HiveObject {
  @HiveField(0)
  String name; // 物品名称
  @HiveField(1)
  String tag; // 物品标签
  @HiveField(2)
  double price; // 物品价格
  @HiveField(3)
  String notes; // 备注
  @HiveField(4)
  String? imagePath; // 图片路径（已弃用，兼容保留）

  /// 构造函数
  Item({
    required this.name,
    required this.tag,
    required this.price,
    required this.notes,
    this.imagePath,
  });
} 