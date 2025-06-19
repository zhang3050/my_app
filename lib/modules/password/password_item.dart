import 'package:hive/hive.dart';
part 'password_item.g.dart';

@HiveType(typeId: 0)
class PasswordItem extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String username;
  @HiveField(2)
  String password;
  @HiveField(3)
  String notes;

  PasswordItem({
    required this.title,
    required this.username,
    required this.password,
    required this.notes,
  });
} 