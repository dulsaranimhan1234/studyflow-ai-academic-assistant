
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5678/webhook';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _authHeaders({
    bool jsonContent = true,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to continue.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain Firebase authentication token.');
    }

    return {
      if (jsonContent) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> debugFirebaseToken() async {
    final user = _auth.currentUser;

    debugPrint('TOKEN TEST STARTED');

    if (user == null) {
      debugPrint('NO USER LOGGED IN');
      return;
    }

    debugPrint('USER LOGGED IN: ${user.email}');

    try {
      final token = await user.getIdToken();
      debugPrint(
        'TOKEN GENERATED: ${token != null && token.isNotEmpty}',
      );
    } catch (e) {
      debugPrint('TOKEN ERROR: $e');
    }
  }

  Future<List<Task>> getTasks() async {
    debugPrint('GET TASKS CALLED');
    final response = await http.get(
      Uri.parse('$baseUrl/studyflow/tasks'),
      headers: await _authHeaders(jsonContent: false),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load tasks: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      throw Exception('The tasks webhook returned an empty response.');
    }

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw Exception('The tasks webhook returned invalid JSON.');
    }

    final List<dynamic> taskList;

    if (data is List) {
      taskList = data;
    } else if (data is Map<String, dynamic> && data['tasks'] is List) {
      taskList = data['tasks'] as List<dynamic>;
    } else {
      throw Exception('Unexpected tasks response format.');
    }

    return taskList
        .map(
          (json) => Task.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<void> completeTask(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/studyflow/task/complete'),
      headers: await _authHeaders(),
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to complete task: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/67acb603-fddd-43d7-90c7-b41bc8751be2/'
        'studyflow/tasks/$id',
      ),
      headers: await _authHeaders(jsonContent: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete task: ${response.statusCode} ${response.body}',
      );
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
        '$baseUrl/77d0d4fa-6d28-47f1-8355-7e092b8af825/'
        'studyflow/tasks/$id',
      ),
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
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
      headers: await _authHeaders(),
      body: jsonEncode({'student': 'Dulsara'}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to generate study plan: ${response.statusCode} ${response.body}',
      );
    }

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw Exception('The AI planner returned invalid JSON.');
    }

    if (data is! Map<String, dynamic> ||
        data['success'] != true ||
        data['plan'] == null) {
      throw Exception('Invalid AI planner response');
    }

    return data['plan'].toString();
  }
}
