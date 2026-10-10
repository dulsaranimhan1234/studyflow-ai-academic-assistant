import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5678/webhook';


Future<List<Task>> getTasks() async {
  final response = await http.get(
    Uri.parse('$baseUrl/studyflow/tasks'),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load tasks: ${response.statusCode} ${response.body}',
    );
  }

  if (response.body.trim().isEmpty) {
    throw Exception(
      'The tasks webhook returned an empty response. '
      'Check the n8n Respond to Webhook node.',
    );
  }

  dynamic data;

  try {
    data = jsonDecode(response.body);
  } on FormatException {
    throw Exception(
      'The tasks webhook returned invalid JSON: ${response.body}',
    );
  }

  final List<dynamic> taskList;

  if (data is List) {
    taskList = data;
  } else if (data is Map<String, dynamic> &&
      data['tasks'] is List) {
    taskList = data['tasks'] as List<dynamic>;
  } else {
    throw Exception(
      'Unexpected tasks response format: ${response.body}',
    );
  }

  return taskList
      .map((json) => Task.fromJson(
            Map<String, dynamic>.from(json as Map),
          ))
      .toList();
}


  Future<void> completeTask(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/studyflow/task/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to complete task');
    }
  }

  
Future<void> deleteTask(int id) async {
  final response = await http.delete(
    Uri.parse(
      '$baseUrl/67acb603-fddd-43d7-90c7-b41bc8751be2/studyflow/tasks/$id',
    ),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to delete task: ${response.body}');
  }
}


  
Future<void> updateTask({
  required int id,
  required String deadline,
  required String priority,
  required String status,
}) async {
  final response = await http.put(
    Uri.parse(
      '$baseUrl/77d0d4fa-6d28-47f1-8355-7e092b8af825/studyflow/tasks/$id',
    ),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'deadline': deadline,
      'priority': priority,
      'status': status,
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Failed to update task: ${response.statusCode} ${response.body}',
    );
  }
}

Future<void> createTask({
  required String student,
  required String subject,
  required String task,
  required String deadline,
  required String priority,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/studyflow/task'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'student': student,
      'subject': subject,
      'task': task,
      'deadline': deadline,
      'priority': priority,
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Failed to create task: ${response.statusCode} ${response.body}',
    );
  }
}

Future<String> generateDailyPlan() async {
  final response = await http.post(
    Uri.parse('$baseUrl/studyflow/ai-planner'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'student': 'Dulsara',
    }),
  );

  if (response.statusCode < 200 ||
      response.statusCode >= 300) {
    throw Exception(
      'Failed to generate study plan: ${response.statusCode} ${response.body}',
    );
  }

  final data = jsonDecode(response.body);

  if (data is! Map<String, dynamic> ||
      data['success'] != true ||
      data['plan'] == null) {
    throw Exception('Invalid AI planner response');
  }

  return data['plan'].toString();
}



}
