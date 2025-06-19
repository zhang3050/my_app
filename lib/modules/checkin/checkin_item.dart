import 'package:hive/hive.dart';
part 'checkin_item.g.dart';

// checkin_item.dart
// 打卡数据模型，Hive持久化结构
@HiveType(typeId: 1)
class CheckinItem extends HiveObject {
  @HiveField(0)
  String title; // 打卡项标题
  @HiveField(1)
  String type; // 打卡类型：daily, weekly, monthly
  @HiveField(2)
  List<String> history; // 打卡历史日期字符串列表

  /// 构造函数
  CheckinItem({
    required this.title,
    required this.type,
    this.history = const [],
  });
} 