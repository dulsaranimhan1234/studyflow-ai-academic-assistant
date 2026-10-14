import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<String?> _getFirebaseIdToken() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('Please log in to continue.');
  }

  final token = await user.getIdToken();

  if (token == null || token.isEmpty) {
    throw Exception('Could not obtain Firebase authentication token.');
  }

  return token;
}

class ApiService {
  static const String baseUrl = 'http://localhost:5678/webhook';
  static final http.Client _defaultClient = http.Client();

  ApiService({
    http.Client? client,
    Future<String?> Function()? tokenProvider,
    String? baseUrl,
    this.aiPlannerTimeout = const Duration(seconds: 30),
  }) : _client = client ?? _defaultClient,
       _tokenProvider = tokenProvider ?? _getFirebaseIdToken,
       _baseUrl = baseUrl ?? ApiService.baseUrl;

  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  final String _baseUrl;
  final Duration aiPlannerTimeout;

  Future<Map<String, String>> _authHeaders({bool jsonContent = true}) async {
    final token = await _tokenProvider();

    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain Firebase authentication token.');
    }

    return {
      if (jsonContent) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    String networkErrorMessage = 'Could not connect to StudyFlow services. Check your connection and try again.',
  }) async {
    try {
      return await request();
    } on http.ClientException {
      throw ApiException(networkErrorMessage);
    }
  }

  Future<void> debugFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('TOKEN TEST STARTED');

    if (user == null) {
      debugPrint('NO USER LOGGED IN');
      return;
    }

    debugPrint('SIGNED-IN USER DETECTED');

    try {
      final token = await user.getIdToken();
      debugPrint('TOKEN GENERATED: ${token != null && token.isNotEmpty}');
    } catch (_) {
      debugPrint('FIREBASE TOKEN RETRIEVAL FAILED');
    }
  }

  Future<List<Task>> getTasks() async {
    debugPrint('GET TASKS CALLED');
    final response =
        await _send(
          () async => _client.get(
            Uri.parse('$_baseUrl/studyflow/tasks'),
            headers: await _authHeaders(jsonContent: false),
          ),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
            'The tasks service did not respond. Please try again.',
          ),
        );

    if (response.statusCode != 200) {
      throw const ApiException(
        'Could not load tasks. Please try again shortly.',
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
        .map((json) => Task.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> completeTask(int id) async {
    final response = await _send(
      () async => _client.post(
        Uri.parse('$_baseUrl/studyflow/task/complete'),
        headers: await _authHeaders(),
        body: jsonEncode({'id': id}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException(
        'The task could not be completed. Please try again.',
      );
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await _send(
      () async => _client.delete(
        Uri.parse(
          '$_baseUrl/67acb603-fddd-43d7-90c7-b41bc8751be2/'
          'studyflow/tasks/$id',
        ),
        headers: await _authHeaders(jsonContent: false),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException(
        'The task could not be deleted. Please try again.',
      );
    }
  }

  Future<void> updateTask({
    required int id,
    required String deadline,
    required String priority,
    required String status,
  }) async {
    final response = await _send(
      () async => _client.put(
        Uri.parse(
          '$_baseUrl/77d0d4fa-6d28-47f1-8355-7e092b8af825/'
          'studyflow/tasks/$id',
        ),
        headers: await _authHeaders(),
        body: jsonEncode({
          'deadline': deadline,
          'priority': priority,
          'status': status,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException(
        'The task could not be updated. Please try again.',
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
    final response = await _send(
      () async => _client.post(
        Uri.parse('$_baseUrl/studyflow/task'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'student': student,
          'subject': subject,
          'task': task,
          'deadline': deadline,
          'priority': priority,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException(
        'The task could not be created. Please try again.',
      );
    }
  }

  Future<String> generateDailyPlan() async {
    late final http.Response response;
    try {
      response = await _send(
        () async => _client.post(
          Uri.parse('$_baseUrl/studyflow/ai-planner'),
          headers: await _authHeaders(),
          body: jsonEncode({'student': 'Dulsara'}),
        ),
        networkErrorMessage: 'Could not connect to the study planner. Check your connection and try again.',
      ).timeout(aiPlannerTimeout);
    } on TimeoutException {
      throw const ApiException(
        'The study planner is taking longer than expected. Please try again.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw const ApiException(
          'The study planner is temporarily at its request limit. Please try again later.',
        );
      }
      if (response.statusCode >= 500) {
        throw const ApiException(
          'The study planner is temporarily unavailable. Please try again shortly.',
        );
      }
      throw const ApiException(
        'Could not generate a study plan. Please try again.',
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
