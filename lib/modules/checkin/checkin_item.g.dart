// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

// checkin_item.g.dart
// Hive自动生成的CheckinItem适配器代码，用于本地序列化/反序列化

class CheckinItemAdapter extends TypeAdapter<CheckinItem> {
  @override
  final int typeId = 1;

  @override
  CheckinItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckinItem(
      title: fields[0] as String,
      type: fields[1] as String,
      history: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CheckinItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.history);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
