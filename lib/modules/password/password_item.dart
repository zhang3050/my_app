import 'package:hive/hive.dart';
part 'password_item.g.dart';

@HiveType(typeId: 0)
class PasswordItem extends HiveObject {
  @HiveField(0)
  String title; // 密码项标题
  @HiveField(1)
  String username; // 账号
  @HiveField(2)
  String password; // 密码内容
  @HiveField(3)
  String notes; // 备注

  /// 构造函数
  PasswordItem({
    required this.title,
    required this.username,
    required this.password,
    required this.notes,
  });
} 