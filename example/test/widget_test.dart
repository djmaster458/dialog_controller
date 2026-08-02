// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:example/app.dart';

void main() {
  testWidgets('renders the dialog demo and shows queued dialogs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter Dialog Demo'), findsOneWidget);
    expect(find.text('Queue info'), findsOneWidget);
    expect(find.text('Flutter BLoC Integration'), findsOneWidget);
    expect(find.text('Riverpod Integration'), findsOneWidget);

    await tester.tap(find.text('Queue alert'));
    await tester.pumpAndSettle();

    expect(find.text('Priority Test Dialog'), findsOneWidget);
    expect(find.text('Queue higher (+30)'), findsOneWidget);
  });
}
