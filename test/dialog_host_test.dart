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

  testWidgets('barrier targets rendered entry before the host rebuilds', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();
    addTearDown(controller.dispose);
    final DialogOutcomeHandle<String> first = controller
        .enqueueForOutcomeWithHandle<String>(
          const DialogRequest(id: 'first', payload: 'First'),
        );

    await tester.pumpWidget(
      MaterialApp(
        home: DialogHost(
          controller: controller,
          builder: _dialogBuilder,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    final DialogRequestHandle next = controller.enqueue(
      const DialogRequest(id: 'next', payload: 'Next', priority: 10),
    );
    // The queue changed, but the barrier still belongs to the first entry.
    await tester.tapAt(const Offset(2, 2));

    expect((await first.outcome).isDismissed, isTrue);
    expect(controller.currentHandle(), same(next));
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets(
    'outgoing action targets its entry rather than the current dialog',
    (WidgetTester tester) async {
      final DialogController controller = DialogController();
      addTearDown(controller.dispose);
      final DialogOutcomeHandle<String> first = controller
          .enqueueForOutcomeWithHandle<String>(
            const DialogRequest(id: 'first', payload: 'First'),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: DialogHost(
            controller: controller,
            builder: (context, request, dismiss) => TextButton(
              onPressed: () =>
                  dismiss(const DialogOutcome<Object?>.confirmed('accepted')),
              child: Text(request.payload! as String),
            ),
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      final DialogRequestHandle next = controller.enqueue(
        const DialogRequest(id: 'next', payload: 'Next', priority: 10),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Invoke the outgoing widget's action while both entries are mounted.
      final TextButton outgoing = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'First'),
      );
      outgoing.onPressed!();

      final DialogOutcome<String> outcome = await first.outcome;
      expect(outcome.isConfirmed, isTrue);
      expect(outcome.value, 'accepted');
      expect(controller.currentHandle(), same(next));
      // Repeated callbacks from the removed entry must be harmless.
      outgoing.onPressed!();
      expect(controller.currentHandle(), same(next));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    },
  );

  testWidgets('replacement rebuilds content and preserves dismissal outcome', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();
    addTearDown(controller.dispose);
    final DialogOutcomeHandle<String> pending = controller
        .enqueueForOutcomeWithHandle<String>(
          const DialogRequest(id: 'status', payload: 'Loading'),
        );
    await tester.pumpWidget(
      MaterialApp(
        home: DialogHost(
          controller: controller,
          builder: (context, request, dismiss) => TextButton(
            onPressed: () =>
                dismiss(const DialogOutcome<Object?>.confirmed('done')),
            child: Text(request.payload! as String),
          ),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    expect(find.text('Loading'), findsOneWidget);
    expect(
      controller.replace(
        pending.handle,
        const DialogRequest(id: 'status', payload: 'Ready'),
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Ready'), findsOneWidget);
    expect(controller.currentHandle(), same(pending.handle));
    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    expect((await pending.outcome).value, 'done');
    expect(controller.hasRequests, isFalse);
  });

  testWidgets('stale callback cannot dismiss the same request enqueued again', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();
    addTearDown(controller.dispose);
    const DialogRequest request = DialogRequest(
      id: 'shared',
      payload: 'Shared',
    );
    final DialogRequestHandle first = controller.enqueue(request);
    late DialogDismissCallback staleDismiss;

    await tester.pumpWidget(
      MaterialApp(
        home: DialogHost(
          controller: controller,
          builder: (context, request, dismiss) {
            staleDismiss = dismiss;
            return const Text('Shared');
          },
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    final DialogDismissCallback dismissFirst = staleDismiss;
    controller.dismiss(first);
    final DialogRequestHandle next = controller.enqueue(request);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Shared'), findsNWidgets(2));
    dismissFirst(const DialogOutcome<Object?>.cancelled());
    expect(controller.currentHandle(), same(next));
    await tester.pumpAndSettle();
    expect(find.text('Shared'), findsOneWidget);
  });

  testWidgets(
    'shows active dialog across multiple hosts using same controller',
    (WidgetTester tester) async {
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
    },
  );

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
        widgetBuilder:
            (
              BuildContext context,
              DialogRequest request,
              DialogDismissCallback dismiss,
            ) {
              return Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Custom widget dialog'),
                    TextButton(
                      onPressed: dismiss,
                      child: const Text('Close custom'),
                    ),
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
        widgetBuilder:
            (
              BuildContext context,
              DialogRequest request,
              DialogDismissCallback dismiss,
            ) {
              return Material(
                child: TextButton(
                  onPressed: () => dismiss(
                    const DialogOutcome<Object?>.confirmed('accepted'),
                  ),
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
