import 'package:flutter_test/flutter_test.dart';

import 'package:studyflow_mobile/main.dart';

void main() {
  testWidgets('StudyFlow app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyFlowApp());

    expect(find.text('StudyFlow'), findsOneWidget);
  });
}
