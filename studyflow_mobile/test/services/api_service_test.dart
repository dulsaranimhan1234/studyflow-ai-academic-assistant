import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyflow_mobile/services/api_service.dart';

const _baseUrl = 'https://unit.test/webhook';
const _testToken = 'test-only-token';

ApiService _service(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ApiService(
    client: MockClient(handler),
    tokenProvider: () async => _testToken,
    baseUrl: _baseUrl,
  );
}

void main() {
  group('ApiService.getTasks', () {
    test('parses a successful task list and sends the Bearer header', () async {
      final service = _service((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('$_baseUrl/studyflow/tasks'));
        expect(request.headers['authorization'], 'Bearer $_testToken');
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'student': 'Dulsara',
              'subject': 'History',
              'task': 'Read chapter three',
              'deadline': '2026-10-22',
              'priority': 'Medium',
              'days_remaining': 8,
              'urgency': 'Upcoming',
              'status': 'pending',
            },
          ]),
          200,
        );
      });

      final tasks = await service.getTasks();

      expect(tasks, hasLength(1));
      expect(tasks.single.id, 7);
      expect(tasks.single.subject, 'History');
      expect(tasks.single.task, 'Read chapter three');
    });

    test('accepts the supported tasks wrapper response', () async {
      final service = _service((_) async {
        return http.Response(jsonEncode({'tasks': []}), 200);
      });

      expect(await service.getTasks(), isEmpty);
    });

    test('throws on an unsuccessful HTTP response', () async {
      final service = _service((_) async => http.Response('unavailable', 503));

      await expectLater(service.getTasks(), throwsA(isA<ApiException>()));
    });

    test('does not expose an HTTP response body on task errors', () async {
      final service = _service(
        (_) async => http.Response('private upstream detail', 503),
      );

      await expectLater(
        service.getTasks(),
        throwsA(
          predicate(
            (error) =>
                error is ApiException &&
                !error.message.contains('private upstream detail'),
          ),
        ),
      );
    });

    test('throws on malformed successful JSON', () async {
      final service = _service((_) async => http.Response('{invalid', 200));

      await expectLater(
        service.getTasks(),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'The tasks webhook returned invalid JSON.',
            ),
          ),
        ),
      );
    });

    test('maps task network failures to a safe service error', () async {
      final service = _service((_) async {
        throw http.ClientException('offline');
      });

      await expectLater(service.getTasks(), throwsA(isA<ApiException>()));
    });
  });

  group('ApiService.generateDailyPlan', () {
    test('returns a plan from the expected successful response', () async {
      final service = ApiService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url,
            Uri.parse('http://localhost:5678/webhook/studyflow/ai-planner'),
          );
          expect(request.headers['authorization'], 'Bearer $_testToken');
          expect(request.headers['content-type'], 'application/json');
          expect(jsonDecode(request.body), {'student': 'Dulsara'});
          return http.Response(
            jsonEncode({'success': true, 'plan': 'Review biology, then rest.'}),
            200,
          );
        }),
        tokenProvider: () async => _testToken,
      );

      expect(await service.generateDailyPlan(), 'Review biology, then rest.');
    });

    test('maps HTTP 429 to a safe rate-limit message', () async {
      final service = _service(
        (_) async => http.Response('private quota details', 429),
      );

      await expectLater(
        service.generateDailyPlan(),
        throwsA(
          predicate(
            (error) =>
                error is ApiException &&
                error.message.contains('request limit') &&
                !error.message.contains('private quota details'),
          ),
        ),
      );
    });

    test('maps HTTP 503 to a temporary service message', () async {
      final service = _service(
        (_) async => http.Response('private service details', 503),
      );

      await expectLater(
        service.generateDailyPlan(),
        throwsA(
          predicate(
            (error) =>
                error is ApiException &&
                error.message.contains('temporarily unavailable') &&
                !error.message.contains('private service details'),
          ),
        ),
      );
    });

    test(
      'throws on malformed JSON or a response missing the plan contract',
      () async {
        final malformedJson = _service(
          (_) async => http.Response('{invalid', 200),
        );
        final incompleteResponses = [
          {'success': true},
          {'success': false, 'plan': 'unused'},
          {'success': true, 'plan': null},
          ['unexpected top-level list'],
        ];

        await expectLater(
          malformedJson.generateDailyPlan(),
          throwsA(
            predicate(
              (error) => error.toString().contains(
                'The AI planner returned invalid JSON.',
              ),
            ),
          ),
        );
        for (final body in incompleteResponses) {
          final service = _service(
            (_) async => http.Response(jsonEncode(body), 200),
          );

          await expectLater(
            service.generateDailyPlan(),
            throwsA(
              predicate(
                (error) =>
                    error.toString().contains('Invalid AI planner response'),
              ),
            ),
          );
        }
      },
    );

    test(
      'does not send a request when the token provider has no token',
      () async {
        var requestWasSent = false;
        final service = ApiService(
          client: MockClient((_) async {
            requestWasSent = true;
            return http.Response('', 200);
          }),
          tokenProvider: () async => null,
          baseUrl: _baseUrl,
        );

        await expectLater(
          service.generateDailyPlan(),
          throwsA(
            predicate(
              (error) => error.toString().contains(
                'Could not obtain Firebase authentication token.',
              ),
            ),
          ),
        );
        expect(requestWasSent, isFalse);
      },
    );

    test('propagates a network client error', () async {
      final service = _service((_) async {
        throw http.ClientException('offline');
      });

      await expectLater(
        service.generateDailyPlan(),
        throwsA(
          predicate(
            (error) =>
                error is ApiException &&
                error.message.contains('Check your connection'),
          ),
        ),
      );
    });

    test('applies a configurable timeout to the planner request', () async {
      final service = ApiService(
        client: MockClient((_) => Completer<http.Response>().future),
        tokenProvider: () async => _testToken,
        baseUrl: _baseUrl,
        aiPlannerTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        service.generateDailyPlan(),
        throwsA(
          predicate(
            (error) =>
                error is ApiException &&
                error.message.contains('taking longer than expected'),
          ),
        ),
      );
    });
  });

  test('createTask sends the existing request fields', () async {
    final service = _service((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$_baseUrl/studyflow/task'));
      expect(request.headers['authorization'], 'Bearer $_testToken');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'student': 'Dulsara',
        'subject': 'History',
        'task': 'Read chapter three',
        'deadline': '2026-10-22',
        'priority': 'Medium',
      });
      return http.Response('', 201);
    });

    await service.createTask(
      student: 'Dulsara',
      subject: 'History',
      task: 'Read chapter three',
      deadline: '2026-10-22',
      priority: 'Medium',
    );
  });

  test('completeTask sends the existing completion request', () async {
    final service = _service((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$_baseUrl/studyflow/task/complete'));
      expect(request.headers['authorization'], 'Bearer $_testToken');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {'id': 7});
      return http.Response('', 200);
    });

    await service.completeTask(7);
  });

  test('updateTask sends the existing update request fields', () async {
    final service = _service((request) async {
      expect(request.method, 'PUT');
      expect(
        request.url,
        Uri.parse(
          '$_baseUrl/77d0d4fa-6d28-47f1-8355-7e092b8af825/studyflow/tasks/7',
        ),
      );
      expect(request.headers['authorization'], 'Bearer $_testToken');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'deadline': '2026-10-23',
        'priority': 'High',
        'status': 'pending',
      });
      return http.Response('', 200);
    });

    await service.updateTask(
      id: 7,
      deadline: '2026-10-23',
      priority: 'High',
      status: 'pending',
    );
  });

  test('deleteTask sends the existing delete request', () async {
    final service = _service((request) async {
      expect(request.method, 'DELETE');
      expect(
        request.url,
        Uri.parse(
          '$_baseUrl/67acb603-fddd-43d7-90c7-b41bc8751be2/studyflow/tasks/7',
        ),
      );
      expect(request.headers['authorization'], 'Bearer $_testToken');
      expect(request.headers.containsKey('content-type'), isFalse);
      return http.Response('', 200);
    });

    await service.deleteTask(7);
  });

  test(
    'task mutations hide server response details on HTTP failures',
    () async {
      final operations = <Future<void> Function(ApiService)>[
        (service) => service.createTask(
          student: 'Dulsara',
          subject: 'History',
          task: 'Read chapter three',
          deadline: '2026-10-22',
          priority: 'Medium',
        ),
        (service) => service.completeTask(7),
        (service) => service.updateTask(
          id: 7,
          deadline: '2026-10-23',
          priority: 'High',
          status: 'pending',
        ),
        (service) => service.deleteTask(7),
      ];

      for (final operation in operations) {
        final service = _service(
          (_) async => http.Response('private server detail', 503),
        );

        await expectLater(
          operation(service),
          throwsA(
            predicate(
              (error) =>
                  error is ApiException &&
                  !error.message.contains('private server detail'),
            ),
          ),
        );
      }
    },
  );

  test('createTask does not expose raw server errors', () async {
    final service = _service(
      (_) async => http.Response('private server response', 500),
    );

    await expectLater(
      service.createTask(
        student: 'Dulsara',
        subject: 'History',
        task: 'Read chapter three',
        deadline: '2026-10-22',
        priority: 'Medium',
      ),
      throwsA(
        predicate(
          (error) =>
              error is ApiException &&
              !error.message.contains('private server response'),
        ),
      ),
    );
  });
}
