import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  test('orders dialogs by priority then insertion order', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'low', priority: 1));
    controller.enqueue(const DialogRequest(id: 'high-a', priority: 10));
    controller.enqueue(const DialogRequest(id: 'high-b', priority: 10));

    expect(controller.current()?.id, 'high-a');
    expect(
      controller.requests().map((DialogRequest request) => request.id),
      <String>['high-a', 'high-b', 'low'],
    );
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

  test('currentHandle identifies queued entries independently of requests', () {
    final DialogController controller = DialogController();
    addTearDown(controller.dispose);
    const DialogRequest request = DialogRequest(id: 'shared');

    expect(controller.currentHandle(), isNull);
    final DialogRequestHandle first = controller.enqueue(request);
    final DialogRequestHandle second = controller.enqueue(
      const DialogRequest(id: 'second'),
    );
    expect(controller.currentHandle(), same(first));

    final DialogRequestHandle high = controller.enqueue(
      const DialogRequest(id: 'high', priority: 10),
    );
    expect(controller.currentHandle(), same(high));
    expect(controller.dismiss(first), isTrue);
    expect(controller.currentHandle(), same(high));
    expect(controller.dismiss(high), isTrue);
    expect(controller.currentHandle(), same(second));
    expect(controller.dismiss(second), isTrue);
    expect(controller.currentHandle(), isNull);
  });

  test('dismisses the current dialog', () {
    final DialogController controller = DialogController();

    controller.enqueue(const DialogRequest(id: 'first', priority: 1));
    controller.enqueue(const DialogRequest(id: 'second', priority: 2));

    expect(controller.dismissCurrent(), isTrue);
    expect(controller.current()?.id, 'first');
  });

  test(
    'rejects duplicate IDs through every enqueue API without mutation',
    () async {
      final DialogController controller = DialogController();
      addTearDown(controller.dispose);
      const DialogRequest request = DialogRequest(id: 'shared', priority: -1);
      final DialogOutcomeHandle<String> pending = controller
          .enqueueForOutcomeWithHandle<String>(request);
      controller.enqueue(const DialogRequest(id: 'high', priority: 10));
      int notifications = 0;
      controller.addListener(() => notifications++);

      for (final DialogRequest duplicate in <DialogRequest>[
        request,
        request.copyWith(priority: 100),
      ]) {
        expect(() => controller.enqueue(duplicate), throwsArgumentError);
        expect(
          () => controller.enqueueForOutcome<String>(duplicate),
          throwsArgumentError,
        );
        expect(
          () => controller.enqueueForOutcomeWithHandle<String>(duplicate),
          throwsArgumentError,
        );
        expect(
          () => controller.enqueueForResult<String>(duplicate),
          throwsArgumentError,
        );
      }

      expect(notifications, 0);
      expect(controller.requests(), hasLength(2));
      expect(controller.current()?.id, 'high');
      controller.dismissWithOutcome(
        pending.handle,
        const DialogOutcome<Object?>.confirmed('original'),
      );
      expect((await pending.outcome).value, 'original');
    },
  );

  test('removed IDs can be reused without reviving stale handles', () {
    final DialogController controller = DialogController();
    addTearDown(controller.dispose);
    const DialogRequest request = DialogRequest(id: 'shared');
    final DialogRequestHandle first = controller.enqueue(request);
    controller.dismiss(first);
    final DialogRequestHandle next = controller.enqueue(request);

    expect(next, isNot(same(first)));
    expect(controller.dismiss(first), isFalse);
    expect(controller.currentHandle(), same(next));
    controller.clear();
    expect(() => controller.enqueue(request), returnsNormally);
  });

  test(
    'replace rejects another entry ID without changing queue or outcomes',
    () async {
      final DialogController controller = DialogController();
      addTearDown(controller.dispose);
      final DialogOutcomeHandle<String> pending = controller
          .enqueueForOutcomeWithHandle<String>(const DialogRequest(id: 'old'));
      controller.enqueue(const DialogRequest(id: 'other'));
      int notifications = 0;
      controller.addListener(() => notifications++);
      bool completed = false;
      pending.outcome.then((_) => completed = true);

      expect(
        () => controller.replace(
          pending.handle,
          const DialogRequest(id: 'other', priority: 10),
        ),
        throwsArgumentError,
      );
      await Future<void>.value();
      expect(completed, isFalse);
      expect(notifications, 0);
      expect(controller.currentHandle(), same(pending.handle));

      expect(controller.requests().map((request) => request.id), <String>[
        'old',
        'other',
      ]);
      expect(
        controller.replace(
          pending.handle,
          const DialogRequest(id: 'new', priority: 10),
        ),
        isTrue,
      );
      await Future<void>.value();
      expect(completed, isFalse);
      expect(notifications, 1);
      expect(controller.requests().map((request) => request.id), <String>[
        'new',
        'other',
      ]);
      controller.dismissWithOutcome(
        pending.handle,
        const DialogOutcome<Object?>.confirmed('updated'),
      );
      expect((await pending.outcome).value, 'updated');
    },
  );

  test('IDs are unique per controller, not globally', () {
    final DialogController first = DialogController();
    final DialogController second = DialogController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    const DialogRequest request = DialogRequest(id: 'shared');
    first.enqueue(request);
    expect(() => second.enqueue(request), returnsNormally);
  });

  test('completes queued dialog with typed outcome', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<bool>> result = controller
        .enqueueForOutcome<bool>(const DialogRequest(id: 'decision'));

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

    final DialogOutcomeHandle<bool> pending = controller
        .enqueueForOutcomeWithHandle<bool>(
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

    final Future<DialogOutcome<String>> result = controller
        .enqueueForOutcome<String>(const DialogRequest(id: 'pending'));

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

  test(
    'dismissal rejects foreign handles with matching entry tokens',
    () async {
      final DialogController first = DialogController();
      final DialogController second = DialogController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      // Both controllers allocate token zero for their first entry.
      final DialogOutcomeHandle<String> firstPending = first
          .enqueueForOutcomeWithHandle<String>(
            const DialogRequest(id: 'first'),
          );
      final DialogOutcomeHandle<String> secondPending = second
          .enqueueForOutcomeWithHandle<String>(
            const DialogRequest(id: 'second'),
          );
      int firstNotifications = 0;
      int secondNotifications = 0;
      first.addListener(() => firstNotifications++);
      second.addListener(() => secondNotifications++);
      bool firstCompleted = false;
      bool secondCompleted = false;
      firstPending.outcome.then((_) => firstCompleted = true);
      secondPending.outcome.then((_) => secondCompleted = true);

      expect(first.dismiss(secondPending.handle), isFalse);
      expect(second.dismiss(firstPending.handle), isFalse);
      expect(
        first.dismissWithOutcome(
          secondPending.handle,
          const DialogOutcome<Object?>.confirmed('foreign'),
        ),
        isFalse,
      );
      expect(
        second.dismissWithOutcome(
          firstPending.handle,
          const DialogOutcome<Object?>.confirmed('foreign'),
        ),
        isFalse,
      );
      await Future<void>.value();

      expect(firstNotifications, 0);
      expect(secondNotifications, 0);
      expect(firstCompleted, isFalse);
      expect(secondCompleted, isFalse);
      expect(first.currentHandle(), same(firstPending.handle));
      expect(second.currentHandle(), same(secondPending.handle));
      expect(first.requests().single.id, 'first');
      expect(second.requests().single.id, 'second');

      expect(
        first.dismissWithOutcome(
          firstPending.handle,
          const DialogOutcome<Object?>.confirmed('first result'),
        ),
        isTrue,
      );
      expect(second.dismiss(secondPending.handle), isTrue);
      expect((await firstPending.outcome).value, 'first result');
      expect((await secondPending.outcome).isDismissed, isTrue);
      expect(firstNotifications, 1);
      expect(secondNotifications, 1);
    },
  );

  test(
    'dismissCurrentWithOutcome resolves current request with custom outcome',
    () async {
      final DialogController controller = DialogController();

      final Future<DialogOutcome<int>> pendingOutcome = controller
          .enqueueForOutcome<int>(const DialogRequest(id: 'pending'));

      expect(
        controller.dismissCurrentWithOutcome(
          outcome: const DialogOutcome<Object?>.cancelled(7),
        ),
        isTrue,
      );

      final DialogOutcome<int> outcome = await pendingOutcome;
      expect(outcome.isCancelled, isTrue);
      expect(outcome.value, 7);
    },
  );

  test('clear dismisses all pending outcomes', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<String>> firstOutcome = controller
        .enqueueForOutcome<String>(const DialogRequest(id: 'first'));
    final Future<DialogOutcome<String>> secondOutcome = controller
        .enqueueForOutcome<String>(const DialogRequest(id: 'second'));

    controller.clear();

    final DialogOutcome<String> resolvedFirst = await firstOutcome;
    final DialogOutcome<String> resolvedSecond = await secondOutcome;
    expect(resolvedFirst.isDismissed, isTrue);
    expect(resolvedSecond.isDismissed, isTrue);
  });

  test(
    'replace updates one entry and preserves handle and priority tie order',
    () {
      final DialogController controller = DialogController();
      addTearDown(controller.dispose);
      final DialogRequestHandle first = controller.enqueue(
        const DialogRequest(id: 'first', priority: 1),
      );
      final DialogRequestHandle second = controller.enqueue(
        const DialogRequest(id: 'second', priority: 2),
      );
      int notifications = 0;
      controller.addListener(() => notifications++);

      expect(
        controller.replace(
          first,
          const DialogRequest(id: 'first', priority: 2, payload: 'updated'),
        ),
        isTrue,
      );
      expect(controller.currentHandle(), same(first));
      expect(controller.current()?.payload, 'updated');
      expect(controller.requests().map((request) => request.id), <String>[
        'first',
        'second',
      ]);
      expect(notifications, 1);

      expect(
        controller.replace(
          first,
          const DialogRequest(id: 'renamed', priority: -10),
        ),
        isTrue,
      );
      expect(controller.currentHandle(), same(second));
      expect(controller.requests().map((request) => request.id), <String>[
        'second',
        'renamed',
      ]);
      // Changing IDs releases the old ID without changing the entry handle.
      expect(
        () => controller.enqueue(const DialogRequest(id: 'first')),
        returnsNormally,
      );
      expect(controller.dismiss(first), isTrue);
    },
  );

  test('replace ignores stale and foreign handles without notification', () {
    final DialogController controller = DialogController();
    final DialogController other = DialogController();
    addTearDown(controller.dispose);
    addTearDown(other.dispose);
    final DialogRequestHandle foreign = other.enqueue(
      const DialogRequest(id: 'other'),
    );
    final DialogRequestHandle stale = controller.enqueue(
      const DialogRequest(id: 'reused'),
    );
    controller.dismiss(stale);
    final DialogRequestHandle active = controller.enqueue(
      const DialogRequest(id: 'reused'),
    );
    int notifications = 0;
    controller.addListener(() => notifications++);

    expect(
      controller.replace(stale, const DialogRequest(id: 'reused')),
      isFalse,
    );
    expect(
      controller.replace(foreign, const DialogRequest(id: 'new')),
      isFalse,
    );
    expect(notifications, 0);
    expect(controller.currentHandle(), same(active));
    expect(controller.current()?.id, 'reused');
  });

  test('dispose resolves all pending outcomes as dismissed', () async {
    final DialogController controller = DialogController();

    final Future<DialogOutcome<bool>> pending = controller
        .enqueueForOutcome<bool>(const DialogRequest(id: 'dispose-me'));

    controller.dispose();

    final DialogOutcome<bool> resolved = await pending;
    expect(resolved.isDismissed, isTrue);
    expect(resolved.value, isNull);
  });
}
