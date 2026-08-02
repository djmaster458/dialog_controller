import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  test('copyWith updates provided values and preserves unspecified values', () {
    const DialogRequest original = DialogRequest(
      id: 'request-1',
      payload: 'original',
      orderingData: 'order-a',
      priority: 1,
      scopeId: 'scope-a',
      sequence: 9,
    );

    final DialogRequest updated = original.copyWith(
      payload: 'updated',
      orderingData: 'order-b',
      priority: 10,
    );

    expect(updated.id, 'request-1');
    expect(updated.payload, 'updated');
    expect(updated.orderingData, 'order-b');
    expect(updated.priority, 10);
    expect(updated.scopeId, 'scope-a');
    expect(updated.sequence, 9);
  });

  test('copyWith retains widgetBuilder when not replaced', () {
    final DialogRequest request = DialogRequest(
      id: 'with-builder',
      widgetBuilder: _sampleBuilder,
    );

    final DialogRequest copy = request.copyWith(priority: 99);

    expect(identical(copy.widgetBuilder, request.widgetBuilder), isTrue);
    expect(copy.orderingData, isNull);
    expect(copy.priority, 99);
  });

  test('default ordering strategy uses priority then sequence', () {
    const DialogRequest highPriority = DialogRequest(
      id: 'high',
      priority: 5,
      sequence: 2,
    );
    const DialogRequest lowPriority = DialogRequest(
      id: 'low',
      priority: 1,
      sequence: 1,
    );
    const DialogRequest tieA = DialogRequest(
      id: 'tie-a',
      priority: 3,
      sequence: 1,
    );
    const DialogRequest tieB = DialogRequest(
      id: 'tie-b',
      priority: 3,
      sequence: 2,
    );

    expect(defaultDialogOrderStrategy(highPriority, lowPriority), lessThan(0));
    expect(defaultDialogOrderStrategy(lowPriority, highPriority), greaterThan(0));
    expect(defaultDialogOrderStrategy(tieA, tieB), lessThan(0));
    expect(defaultDialogOrderStrategy(tieB, tieA), greaterThan(0));
  });
}

Widget _sampleBuilder(
  BuildContext context,
  DialogRequest request,
  DialogDismissCallback dismiss,
) {
  return const SizedBox.shrink();
}
