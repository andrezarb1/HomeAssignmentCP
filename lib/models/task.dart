class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime createdAt;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    this.notes,
    DateTime? createdAt,
    this.isDone = false,
  }) : createdAt = createdAt ?? DateTime.now();
}
