// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

// password_item.g.dart
// Hive自动生成的PasswordItem适配器代码，用于本地序列化/反序列化

class PasswordItemAdapter extends TypeAdapter<PasswordItem> {
  @override
  final int typeId = 0;

  @override
  PasswordItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordItem(
      title: fields[0] as String,
      username: fields[1] as String,
      password: fields[2] as String,
      notes: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
