import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  test('copyWith updates provided values and preserves unspecified values', () {
    const DialogRequest original = DialogRequest(
      id: 'request-1',
      payload: 'original',
      priority: 1,
    );

    final DialogRequest updated = original.copyWith(
      payload: 'updated',
      priority: 10,
    );

    expect(updated.id, 'request-1');
    expect(updated.payload, 'updated');
    expect(updated.priority, 10);
  });

  test('copyWith retains widgetBuilder when not replaced', () {
    final DialogRequest request = DialogRequest(
      id: 'with-builder',
      widgetBuilder: _sampleBuilder,
    );

    final DialogRequest copy = request.copyWith(priority: 99);

    expect(identical(copy.widgetBuilder, request.widgetBuilder), isTrue);
    expect(copy.priority, 99);
  });
}

Widget _sampleBuilder(
  BuildContext context,
  DialogRequest request,
  DialogDismissCallback dismiss,
) {
  return const SizedBox.shrink();
}
