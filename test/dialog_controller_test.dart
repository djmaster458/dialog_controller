import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  test('orders dialogs by priority then insertion order', () {
    final DialogController controller = DialogController();

    controller.enqueue(
      const DialogRequest(id: 'low', priority: 1),
    );
    controller.enqueue(
      const DialogRequest(id: 'high-a', priority: 10),
    );
    controller.enqueue(
      const DialogRequest(id: 'high-b', priority: 10),
    );

    expect(controller.current()?.id, 'high-a');
    expect(controller.requests().map((DialogRequest request) => request.id), <String>[
      'high-a',
      'high-b',
      'low',
    ]);
  });

  test('hasRequests reflects enqueue and dismissal lifecycle', () {
    final DialogController controller = DialogController();

    expect(controller.hasRequests, isFalse);

    final DialogRequestHandle first = controller.enqueue(
      const DialogRequest(id: 'one'),
    );
    expect(controller.hasRequests, isTrue);

    final DialogRequestHandle second = controller.enqueue(
      const DialogRequest(id: 'two'),
    );
    expect(controller.hasRequests, isTrue);

    expect(controller.dismiss(first), isTrue);
    expect(controller.hasRequests, isTrue);

    expect(controller.dismiss(second), isTrue);
    expect(controller.hasRequests, isFalse);
  });

  test('returns current highest-priority dialog', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'low', priority: 1));
    controller.enqueue(const DialogRequest(id: 'high', priority: 20));

    expect(controller.current()?.id, 'high');
  });

  test('dismisses the current dialog', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'first', priority: 1));
    controller.enqueue(const DialogRequest(id: 'second', priority: 2));

    expect(controller.dismissCurrent(), isTrue);
    expect(controller.current()?.id, 'first');
  });

  test('dismissCurrent targets the active queued dialog when ids repeat', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'shared', priority: 1));
    controller.enqueue(const DialogRequest(id: 'shared', priority: 10));

    expect(controller.current()?.priority, 10);
    expect(controller.dismissCurrent(), isTrue);
    expect(controller.current()?.priority, 1);
  });

  test('supports custom ordering strategy', () {
    int domainRankFirst(DialogRequest a, DialogRequest b) {
      final int aRank = a.orderingData! as int;
      final int bRank = b.orderingData! as int;
      return aRank.compareTo(bRank);
    }

    final DialogController controller = DialogController(
      orderStrategy: domainRankFirst,
    );

    controller.enqueue(
      const DialogRequest(id: 'first', priority: 100, orderingData: 20),
    );
    controller.enqueue(
      const DialogRequest(id: 'second', priority: -100, orderingData: 5),
    );

    expect(controller.current()?.id, 'second');
  });

  test('preserves insertion order when custom strategy ties', () {
    int alwaysTie(DialogRequest a, DialogRequest b) => 0;

    final DialogController controller = DialogController(
      orderStrategy: alwaysTie,
    );

    controller.enqueue(const DialogRequest(id: 'first'));
    controller.enqueue(const DialogRequest(id: 'second'));

    expect(
      controller.requests().map((DialogRequest request) => request.id),
      <String>['first', 'second'],
    );
  });

  test('completes queued dialog with typed outcome', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<bool>> result =
        controller.enqueueForOutcome<bool>(
      const DialogRequest(id: 'decision'),
    );

    expect(
      controller.dismissCurrentWithOutcome(
        outcome: const DialogOutcome<Object?>.confirmed(true),
      ),
      isTrue,
    );
    final DialogOutcome<bool> outcome = await result;
    expect(outcome.isConfirmed, isTrue);
    expect(outcome.value, isTrue);
  });

  test('returns handle and typed outcome when enqueued for outcome', () async {
    final DialogController controller = DialogController();

    final DialogOutcomeHandle<bool> pending =
        controller.enqueueForOutcomeWithHandle<bool>(
      const DialogRequest(id: 'decision-with-handle'),
    );

    expect(
      controller.dismissWithOutcome(
        pending.handle,
        const DialogOutcome<Object?>.confirmed(true),
      ),
      isTrue,
    );

    final DialogOutcome<bool> outcome = await pending.outcome;
    expect(outcome.isConfirmed, isTrue);
    expect(outcome.value, isTrue);
  });

  test('completes pending outcome with null when cleared', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<String>> result =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'pending'),
    );

    controller.clear();
    final DialogOutcome<String> outcome = await result;
    expect(outcome.isDismissed, isTrue);
    expect(outcome.value, isNull);
  });

  test('returns false when dismissing stale request handle', () {
    final DialogController controller = DialogController();

    final DialogRequestHandle handle = controller.enqueue(
      const DialogRequest(id: 'stale'),
    );
    expect(controller.dismiss(handle), isTrue);
    expect(controller.dismiss(handle), isFalse);
    expect(
      controller.dismissWithOutcome(
        handle,
        const DialogOutcome<Object?>.cancelled(),
      ),
      isFalse,
    );
  });

  test('dismissCurrentWithOutcome resolves current request with custom outcome',
      () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<int>> pendingOutcome =
        controller.enqueueForOutcome<int>(
      const DialogRequest(id: 'pending'),
    );

    expect(
      controller.dismissCurrentWithOutcome(
        outcome: const DialogOutcome<Object?>.cancelled(7),
      ),
      isTrue,
    );

    final DialogOutcome<int> outcome = await pendingOutcome;
    expect(outcome.isCancelled, isTrue);
    expect(outcome.value, 7);
  });

  test('clear dismisses all pending outcomes', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<String>> firstOutcome =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'first'),
    );
    final Future<DialogOutcome<String>> secondOutcome =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'second'),
    );

    controller.clear();

    final DialogOutcome<String> resolvedFirst = await firstOutcome;
    final DialogOutcome<String> resolvedSecond = await secondOutcome;
    expect(resolvedFirst.isDismissed, isTrue);
    expect(resolvedSecond.isDismissed, isTrue);
  });

  test('replaceAll dismisses pending outcomes from previous queue', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<String>> oldOutcome =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'old'),
    );

    controller.replaceAll(
      const <DialogRequest>[
        DialogRequest(id: 'new'),
      ],
    );

    final DialogOutcome<String> resolved = await oldOutcome;
    expect(resolved.isDismissed, isTrue);
    expect(controller.current()?.id, 'new');
  });

  test('dispose resolves all pending outcomes as dismissed', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<bool>> pending = controller.enqueueForOutcome<bool>(
      const DialogRequest(id: 'dispose-me'),
    );

    controller.dispose();

    final DialogOutcome<bool> resolved = await pending;
    expect(resolved.isDismissed, isTrue);
    expect(resolved.value, isNull);
  });
}
