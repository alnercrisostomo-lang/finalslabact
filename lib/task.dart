import 'package:hive/hive.dart';

/// A single to-do item stored in Hive.
class Task {
  Task({required this.title, required this.date});

  String title;
  DateTime date;
}

/// Hand-written adapter so you don't need hive_generator / build_runner.
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final title = reader.readString();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Task(title: title, date: date);
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
  }
}
