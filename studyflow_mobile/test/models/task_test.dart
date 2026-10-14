import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow_mobile/models/task.dart';

void main() {
  group('Task.fromJson', () {
    test('parses the fields used by the API response', () {
      final task = Task.fromJson({
        'id': 42,
        'student': 'Dulsara',
        'subject': 'Biology',
        'task': 'Review cell structure',
        'deadline': '2026-10-20',
        'priority': 'High',
        'days_remaining': 6,
        'urgency': 'Soon',
        'status': 'pending',
      });

      expect(task.id, 42);
      expect(task.student, 'Dulsara');
      expect(task.subject, 'Biology');
      expect(task.task, 'Review cell structure');
      expect(task.deadline, '2026-10-20');
      expect(task.priority, 'High');
      expect(task.daysRemaining, 6);
      expect(task.urgency, 'Soon');
      expect(task.status, 'pending');
    });

    test('uses defaults for missing or null fields', () {
      final task = Task.fromJson({
        'id': null,
        'student': null,
        'days_remaining': null,
        'status': null,
      });

      expect(task.id, 0);
      expect(task.student, '');
      expect(task.subject, '');
      expect(task.task, '');
      expect(task.deadline, '');
      expect(task.priority, '');
      expect(task.daysRemaining, 0);
      expect(task.urgency, '');
      expect(task.status, 'pending');
    });

    test('falls back for invalid numeric values and stringifies values', () {
      final task = Task.fromJson({
        'id': 'not-an-integer',
        'student': 123,
        'days_remaining': 'not-an-integer',
      });

      expect(task.id, 0);
      expect(task.student, '123');
      expect(task.daysRemaining, 0);
    });
  });

  test('serializes all existing model fields using parser JSON keys', () {
    final task = Task.fromJson({
      'id': '42',
      'student': 'Dulsara',
      'subject': 'Biology',
      'task': 'Review cell structure',
      'deadline': '2026-10-20',
      'priority': 'High',
      'days_remaining': '6',
      'urgency': 'Soon',
      'status': 'pending',
    });

    expect(task.toJson(), {
      'id': 42,
      'student': 'Dulsara',
      'subject': 'Biology',
      'task': 'Review cell structure',
      'deadline': '2026-10-20',
      'priority': 'High',
      'days_remaining': 6,
      'urgency': 'Soon',
      'status': 'pending',
    });
  });
}
