import 'package:hive/hive.dart';
part 'anniversary_item.g.dart';

@HiveType(typeId: 10)
class AnniversaryItem extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  bool isLunar; // true: 农历，false: 公历
  @HiveField(3)
  String notes;
  @HiveField(4)
  String tag;
  @HiveField(5)
  bool repeatYearly;

  AnniversaryItem({
    required this.name,
    required this.date,
    required this.isLunar,
    required this.notes,
    required this.tag,
    this.repeatYearly = true,
  });
} 