import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  testWidgets('updateShouldNotify only notifies dependents on scope changes', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();
    int dependencyChanges = 0;

    await tester.pumpWidget(
      _scopeTree(
        controller: controller,
        scopeId: 'details',
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 1);

    await tester.pumpWidget(
      _scopeTree(
        controller: controller,
        scopeId: 'details',
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(
      dependencyChanges,
      1,
      reason: 'No dependency change expected for identical controller/scope.',
    );

    await tester.pumpWidget(
      _scopeTree(
        controller: controller,
        scopeId: 'inbox',
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 2);

    controller.dispose();
  });

  testWidgets('updateShouldNotify notifies dependents on controller changes', (
    WidgetTester tester,
  ) async {
    final DialogController firstController = DialogController();
    final DialogController secondController = DialogController();
    int dependencyChanges = 0;

    await tester.pumpWidget(
      _scopeTree(
        controller: firstController,
        scopeId: 'details',
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 1);

    await tester.pumpWidget(
      _scopeTree(
        controller: secondController,
        scopeId: 'details',
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 2);

    firstController.dispose();
    secondController.dispose();
  });
}

Widget _scopeTree({
  required DialogController controller,
  required String scopeId,
  required VoidCallback onDependencyChange,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: DialogScope(
      controller: controller,
      scopeId: scopeId,
      child: _ScopeDependentProbe(onDependencyChange: onDependencyChange),
    ),
  );
}

class _ScopeDependentProbe extends StatefulWidget {
  const _ScopeDependentProbe({required this.onDependencyChange});

  final VoidCallback onDependencyChange;

  @override
  State<_ScopeDependentProbe> createState() => _ScopeDependentProbeState();
}

class _ScopeDependentProbeState extends State<_ScopeDependentProbe> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DialogScope.of(context);
    widget.onDependencyChange();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
