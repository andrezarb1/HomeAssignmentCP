import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? notes;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  bool isDone;

  Task({
    required this.id,
    required this.title,
    this.notes,
    DateTime? createdAt,
    this.isDone = false,
  }) : createdAt = createdAt ?? DateTime.now();
}
