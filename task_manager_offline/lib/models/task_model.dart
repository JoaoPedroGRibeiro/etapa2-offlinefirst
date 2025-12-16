class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final bool isSynced;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isSynced = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['is_completed'] == 1, 
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}