// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';
import 'package:example/app.dart';

void main() {
  testWidgets('renders the dialog demo and shows queued dialogs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter Dialog Demo'), findsOneWidget);
    expect(find.text('Queue info'), findsOneWidget);
    expect(find.text('Flutter BLoC Integration'), findsOneWidget);

    await tester.tap(find.text('Queue alert'));
    await tester.pumpAndSettle();

    expect(find.text('Priority Test Dialog'), findsOneWidget);
    expect(find.text('Queue higher (+30)'), findsOneWidget);

    await tester.ensureVisible(find.text('Close'));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Riverpod Integration'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Riverpod Integration'), findsOneWidget);
  });

  testWidgets('updates a replaceable dialog using its captured handle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());

    final Finder queueButton = find.text('Queue replaceable dialog');
    final DialogHost host = tester.widget<DialogHost>(
      find.ancestor(of: queueButton, matching: find.byType(DialogHost)),
    );
    final DialogController controller = host.controller!;
    final Set<String> generatedIds = <String>{};

    for (int attempt = 0; attempt < 2; attempt++) {
      await tester.tap(queueButton);
      await tester.pumpAndSettle();

      final DialogRequest original = controller.current()!;
      final DialogRequestHandle handle = controller.currentHandle()!;
      expect(generatedIds.add(original.id), isTrue);
      expect(
        find.text('This dialog can be updated using its original handle.'),
        findsOneWidget,
      );
      final DialogRequest following = DialogRequest(
        id: 'following-$attempt',
        priority: original.priority,
        payload: 'Another queued dialog.',
      );
      controller.enqueue(following);
      await tester.pumpAndSettle();

      final SnackBarAction update = tester.widget<SnackBarAction>(
        find.widgetWithText(SnackBarAction, 'Update'),
      );
      // Invoke the action directly so the local dialog barrier cannot intercept
      // the snackbar tap on smaller viewports.
      update.onPressed();
      await tester.pumpAndSettle();

      expect(
        find.text('Updated dialog, same queued entry and handle.'),
        findsOneWidget,
      );
      expect(controller.currentHandle(), same(handle));
      expect(controller.current()!.id, original.id);
      expect(
        controller.requests().map((DialogRequest request) => request.id),
        <String>[original.id, following.id],
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Dismiss'));
      await tester.pumpAndSettle();
      expect(controller.current(), same(following));

      // A delayed Update must not change another entry after the handle expires.
      update.onPressed();
      await tester.pumpAndSettle();
      expect(controller.requests(), <DialogRequest>[following]);
      expect(find.text('Another queued dialog.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Dismiss'));
      ScaffoldMessenger.of(tester.element(queueButton)).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(controller.hasRequests, isFalse);
    }
  });

  for (final String openButton in <String>[
    'Queue alert',
    'Riverpod open priority dialog',
  ]) {
    testWidgets(
      '$openButton queues distinct lower-priority requests repeatedly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MyApp());

        final DialogHost host = tester.widget<DialogHost>(
          find.ancestor(
            of: find.text(openButton),
            matching: find.byType(DialogHost),
          ),
        );
        final DialogController controller = host.controller!;

        await tester.tap(find.text(openButton));
        await tester.pumpAndSettle();

        for (int click = 0; click < 2; click++) {
          await tester.ensureVisible(find.text('Queue lower (0)'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Queue lower (0)'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        expect(find.text('Priority Test Dialog'), findsOneWidget);
        expect(controller.requests(), hasLength(3));
        final Set<String> queuedIds = controller
            .requests()
            .where(
              (DialogRequest request) =>
                  request.priority < controller.current()!.priority,
            )
            .map((DialogRequest request) => request.id)
            .toSet();
        expect(queuedIds, hasLength(2));

        await tester.ensureVisible(find.text('Close'));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        for (int remaining = 2; remaining > 0; remaining--) {
          expect(controller.requests(), hasLength(remaining));
          expect(queuedIds.remove(controller.current()!.id), isTrue);
          expect(find.text('Dismiss'), findsOneWidget);
          await tester.ensureVisible(find.text('Dismiss'));
          await tester.tap(find.text('Dismiss'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        expect(queuedIds, isEmpty);
        expect(controller.hasRequests, isFalse);
        expect(find.text('Dismiss'), findsNothing);
      },
    );
  }
}
