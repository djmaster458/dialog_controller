import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  testWidgets('renders current dialog and dismisses from barrier tap', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();

    await tester.pumpWidget(
      MaterialApp(
        home: DialogScope(
          controller: controller,
          child: DialogHost(
            builder: _dialogBuilder,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    controller.enqueue(
      const DialogRequest(id: 'first', payload: 'Hello dialog'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello dialog'), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(find.text('Hello dialog'), findsNothing);
  });

  testWidgets('shows active dialog across multiple hosts using same controller', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();

    await tester.pumpWidget(
      MaterialApp(
        home: DialogScope(
          controller: controller,
          child: Column(
            children: <Widget>[
              Expanded(
                child: DialogHost(
                  builder: _dialogBuilder,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
              Expanded(
                child: DialogHost(
                  builder: _dialogBuilder,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.enqueue(
      const DialogRequest(id: 'global', payload: 'Global dialog'),
    );

    await tester.pumpAndSettle();

    expect(find.text('Global dialog'), findsNWidgets(2));
  });

  testWidgets('uses request-level widget builder when provided', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();

    await tester.pumpWidget(
      MaterialApp(
        home: DialogScope(
          controller: controller,
          child: DialogHost(
            builder: _dialogBuilder,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    controller.enqueue(
      DialogRequest(
        id: 'custom',
        payload: 'ignored by custom builder',
        widgetBuilder: (
          BuildContext context,
          DialogRequest request,
          DialogDismissCallback dismiss,
        ) {
          return Material(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Custom widget dialog'),
                TextButton(onPressed: dismiss, child: const Text('Close custom')),
              ],
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Custom widget dialog'), findsOneWidget);
    expect(find.text('ignored by custom builder'), findsNothing);

    await tester.tap(find.text('Close custom'));
    await tester.pumpAndSettle();

    expect(find.text('Custom widget dialog'), findsNothing);
  });

  testWidgets('returns outcome from custom dialog action', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();

    await tester.pumpWidget(
      MaterialApp(
        home: DialogScope(
          controller: controller,
          child: DialogHost(
            builder: _dialogBuilder,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    final Future<String?> result = controller.enqueueForResult<String>(
      DialogRequest(
        id: 'result-dialog',
        widgetBuilder: (
          BuildContext context,
          DialogRequest request,
          DialogDismissCallback dismiss,
        ) {
          return Material(
            child: TextButton(
              onPressed: () =>
                  dismiss(const DialogOutcome<Object?>.confirmed('accepted')),
              child: const Text('Accept'),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(await result, 'accepted');
  });
}

Widget _dialogBuilder(
  BuildContext context,
  DialogRequest request,
  DialogDismissCallback dismiss,
) {
  return Material(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(request.payload! as String),
    ),
  );
}
