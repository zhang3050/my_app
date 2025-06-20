// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anniversary_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnniversaryItemAdapter extends TypeAdapter<AnniversaryItem> {
  @override
  final int typeId = 10;

  @override
  AnniversaryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnniversaryItem(
      name: fields[0] as String,
      date: fields[1] as DateTime,
      isLunar: fields[2] as bool,
      notes: fields[3] as String,
      tag: fields[4] as String,
      repeatYearly: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AnniversaryItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.isLunar)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.tag)
      ..writeByte(5)
      ..write(obj.repeatYearly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnniversaryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
