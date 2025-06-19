import 'package:hive/hive.dart';
part 'checkin_item.g.dart';

@HiveType(typeId: 1)
class CheckinItem extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String type; // daily, weekly, monthly
  @HiveField(2)
  List<String> history; // 打卡日期字符串

  CheckinItem({
    required this.title,
    required this.type,
    this.history = const [],
  });
} 