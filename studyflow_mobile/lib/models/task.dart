class Task {
  final int id;
  final String student;
  final String subject;
  final String task;
  final String deadline;
  final String priority;
  final int daysRemaining;
  final String urgency;
  final String status;

  Task({
    required this.id,
    required this.student,
    required this.subject,
    required this.task,
    required this.deadline,
    required this.priority,
    required this.daysRemaining,
    required this.urgency,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.tryParse(json['id'].toString()) ?? 0,
      student: json['student']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      task: json['task']?.toString() ?? '',
      deadline: json['deadline']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      daysRemaining:
          int.tryParse(json['days_remaining']?.toString() ?? '') ?? 0,
      urgency: json['urgency']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
