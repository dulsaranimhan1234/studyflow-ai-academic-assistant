import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studyflow_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutFirebaseAuthPlatform();
  });

  testWidgets('StudyFlow app loads in the signed-out state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to StudyFlow'), findsOneWidget);
    expect(find.text('Sign in to manage your academic life.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? Create one"), findsOneWidget);
    expect(find.text('Your academic workspace'), findsNothing);
  });
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
