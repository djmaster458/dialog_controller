import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dialog/flutter_dialog.dart';

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

    controller.enqueue(const DialogRequest(id: 'one'));
    expect(controller.hasRequests, isTrue);

    controller.enqueue(const DialogRequest(id: 'two'));
    expect(controller.hasRequests, isTrue);

    expect(controller.dismiss('one'), isTrue);
    expect(controller.hasRequests, isTrue);

    expect(controller.dismiss('two'), isTrue);
    expect(controller.hasRequests, isFalse);
  });

  test('filters dialogs by scope', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'global', priority: 1));
    controller.enqueue(const DialogRequest(id: 'scoped', priority: 20, scopeId: 'details'));

    expect(controller.current()?.id, 'global');
    expect(controller.current(scopeId: 'details')?.id, 'scoped');
  });

  test('dismisses the current dialog in a scope', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'first', priority: 1));
    controller.enqueue(const DialogRequest(id: 'second', priority: 2));

    expect(controller.dismissCurrent(), isTrue);
    expect(controller.current()?.id, 'first');
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

  test('completes queued dialog with typed outcome', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<bool>> result =
        controller.enqueueForOutcome<bool>(
      const DialogRequest(id: 'decision'),
    );

    expect(
      controller.dismissWithOutcome(
        'decision',
        const DialogOutcome<Object?>.confirmed(true),
      ),
      isTrue,
    );
    final DialogOutcome<bool> outcome = await result;
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

  test('returns false when dismissing unknown request id', () {
    final DialogController controller = DialogController();

    expect(controller.dismiss('missing'), isFalse);
    expect(
      controller.dismissWithOutcome(
        'missing',
        const DialogOutcome<Object?>.cancelled(),
      ),
      isFalse,
    );
  });

  test('dismissCurrentWithOutcome resolves scoped request with custom outcome',
      () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<int>> scopedOutcome =
        controller.enqueueForOutcome<int>(
      const DialogRequest(id: 'scoped', scopeId: 'details'),
    );

    expect(
      controller.dismissCurrentWithOutcome(
        scopeId: 'details',
        outcome: const DialogOutcome<Object?>.cancelled(7),
      ),
      isTrue,
    );

    final DialogOutcome<int> outcome = await scopedOutcome;
    expect(outcome.isCancelled, isTrue);
    expect(outcome.value, 7);
  });

  test('clear with scope only dismisses matching scope outcomes', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<String>> scopedOutcome =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'scoped', scopeId: 'details'),
    );
    final Future<DialogOutcome<String>> globalOutcome =
        controller.enqueueForOutcome<String>(
      const DialogRequest(id: 'global'),
    );

    controller.clear(scopeId: 'details');

    final DialogOutcome<String> resolvedScoped = await scopedOutcome;
    expect(resolvedScoped.isDismissed, isTrue);

    expect(controller.current()?.id, 'global');
    expect(
      controller.dismissWithOutcome(
        'global',
        const DialogOutcome<Object?>.confirmed('ok'),
      ),
      isTrue,
    );
    final DialogOutcome<String> resolvedGlobal = await globalOutcome;
    expect(resolvedGlobal.isConfirmed, isTrue);
    expect(resolvedGlobal.value, 'ok');
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
