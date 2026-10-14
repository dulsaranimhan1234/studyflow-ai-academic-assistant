import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyflow_mobile/screens/dashboard_screen.dart';
import 'package:studyflow_mobile/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutFirebaseAuthPlatform();
  });

  testWidgets('displays the plan returned by the mocked planner request', (
    WidgetTester tester,
  ) async {
    const plan =
        'STUDY PLAN\n1. Biology review — 25 minutes\nBreak: 10 minutes';
    var plannerRequestWasSent = false;
    final service = _apiService((request) async {
      if (request.method == 'GET') {
        return http.Response('[]', 200);
      }

      if (request.url.path.endsWith('/studyflow/ai-planner')) {
        plannerRequestWasSent = true;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'plan': plan})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return http.Response('not found', 404);
    });
    await tester.pumpWidget(
      MaterialApp(home: DashboardScreen(apiService: service)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate Study Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Study Plan'));
    await tester.pumpAndSettle();

    expect(plannerRequestWasSent, isTrue);
    expect(find.text('Your personalized study plan is ready.'), findsOneWidget);
    expect(find.text('Regenerate Study Plan'), findsOneWidget);
    expect(find.text('Generating your plan...'), findsNothing);
    await tester.tap(find.text('View Full Study Plan'));
    await tester.pumpAndSettle();

    expect(find.text('AI Study Plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Biology review'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Biology review'), findsOneWidget);
    expect(find.text('25 minutes'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('Break: 10 minutes'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Break: 10 minutes'), findsOneWidget);
  });

  testWidgets('shows the existing planner error after an HTTP failure', (
    WidgetTester tester,
  ) async {
    await _expectPlannerFailure(
      tester,
      (_) async => http.Response('private server detail', 503),
      'The study planner is temporarily unavailable. Please try again shortly.',
    );
  });

  testWidgets('shows a safe quota message for HTTP 429', (
    WidgetTester tester,
  ) async {
    await _expectPlannerFailure(
      tester,
      (_) async => http.Response('private quota detail', 429),
      'The study planner is temporarily at its request limit. Please try again later.',
    );
  });

  testWidgets('shows a connection message after a network failure', (
    WidgetTester tester,
  ) async {
    await _expectPlannerFailure(
      tester,
      (_) async => throw http.ClientException('private connection detail'),
      'Could not connect to the study planner. Check your connection and try again.',
    );
  });

  testWidgets('clears the loading state after the planner times out', (
    WidgetTester tester,
  ) async {
    await _expectPlannerFailure(
      tester,
      (_) => Completer<http.Response>().future,
      'The study planner is taking longer than expected. Please try again.',
      timeout: const Duration(milliseconds: 10),
    );
  });
}

ApiService _apiService(
  Future<http.Response> Function(http.Request request) handler, {
  Duration timeout = const Duration(seconds: 30),
}) {
  return ApiService(
    client: MockClient(handler),
    tokenProvider: () async => 'integration-test-token',
    baseUrl: 'https://unit.test/webhook',
    aiPlannerTimeout: timeout,
  );
}

Future<void> _expectPlannerFailure(
  WidgetTester tester,
  Future<http.Response> Function(http.Request request) plannerHandler,
  String expectedMessage, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final service = _apiService((request) async {
    if (request.method == 'GET') return http.Response('[]', 200);
    return plannerHandler(request);
  }, timeout: timeout);

  await tester.pumpWidget(
    MaterialApp(home: DashboardScreen(apiService: service)),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Generate Study Plan'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Generate Study Plan'));
  await tester.pump();
  if (timeout.inMilliseconds < 100) {
    await tester.pump(timeout + const Duration(milliseconds: 1));
  }
  await tester.pumpAndSettle();

  expect(find.text(expectedMessage), findsOneWidget);
  expect(find.textContaining('private'), findsNothing);
  expect(find.text('Generate Study Plan'), findsOneWidget);
  expect(find.text('Generating your plan...'), findsNothing);
}

class _SignedOutFirebaseAuthPlatform extends FirebaseAuthPlatform {
  _SignedOutFirebaseAuthPlatform({super.appInstance});

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return _SignedOutFirebaseAuthPlatform(appInstance: app);
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) {
    return this;
  }

  @override
  UserPlatform? get currentUser => null;

  @override
  Stream<UserPlatform?> authStateChanges() => Stream<UserPlatform?>.value(null);
}
