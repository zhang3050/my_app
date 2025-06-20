// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idea_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IdeaItemAdapter extends TypeAdapter<IdeaItem> {
  @override
  final int typeId = 31;

  @override
  IdeaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IdeaItem(
      title: fields[7] as String,
      content: fields[0] as String,
      tags: (fields[1] as List).cast<String>(),
      createdAt: fields[2] as DateTime,
      isStar: fields[3] as bool,
      isArchived: fields[4] as bool,
      isDeleted: fields[5] as bool,
      deletedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, IdeaItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.tags)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.isStar)
      ..writeByte(4)
      ..write(obj.isArchived)
      ..writeByte(5)
      ..write(obj.isDeleted)
      ..writeByte(6)
      ..write(obj.deletedAt)
      ..writeByte(7)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdeaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
