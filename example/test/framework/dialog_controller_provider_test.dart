import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example/src/framework/dialog_controller_provider.dart';
import 'package:dialog_flow/dialog_flow.dart';

void main() {
  test('provider returns stable controller instance per container', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final DialogController first = container.read(dialogControllerProvider);
    final DialogController second = container.read(dialogControllerProvider);

    expect(identical(first, second), isTrue);
    expect(first.hasRequests, isFalse);
  });

  test('provider creates different controllers for different containers', () {
    final ProviderContainer firstContainer = ProviderContainer();
    final ProviderContainer secondContainer = ProviderContainer();
    addTearDown(firstContainer.dispose);
    addTearDown(secondContainer.dispose);

    final DialogController first = firstContainer.read(dialogControllerProvider);
    final DialogController second = secondContainer.read(dialogControllerProvider);

    expect(identical(first, second), isFalse);
  });
}
