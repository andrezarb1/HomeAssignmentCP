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

  // GPS (optional)
  @HiveField(5)
  final double? latitude;

  @HiveField(6)
  final double? longitude;

  @HiveField(7)
  final String? locationLabel; // e.g. "Leeds, UK"

  Task({
    required this.id,
    required this.title,
    this.notes,
    DateTime? createdAt,
    this.isDone = false,
    this.latitude,
    this.longitude,
    this.locationLabel,
  }) : createdAt = createdAt ?? DateTime.now();
}
