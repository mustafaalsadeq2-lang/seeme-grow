// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'year_photo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class YearPhotoAdapter extends TypeAdapter<YearPhoto> {
  @override
  final int typeId = 1;

  @override
  YearPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YearPhoto(
      childId: fields[0] as String,
      age: fields[1] as int,
      mainPath: fields[2] as String,
      extraPaths: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, YearPhoto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.childId)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.mainPath)
      ..writeByte(3)
      ..write(obj.extraPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearPhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
