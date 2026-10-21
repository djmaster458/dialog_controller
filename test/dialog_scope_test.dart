import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dialog_controller/dialog_controller.dart';

void main() {
  testWidgets('updateShouldNotify does not notify for identical controller', (
    WidgetTester tester,
  ) async {
    final DialogController controller = DialogController();
    int dependencyChanges = 0;

    await tester.pumpWidget(
      _scopeTree(
        controller: controller,
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 1);

    await tester.pumpWidget(
      _scopeTree(
        controller: controller,
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(
      dependencyChanges,
      1,
      reason: 'No dependency change expected for identical controller.',
    );

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
        onDependencyChange: () => dependencyChanges++,
      ),
    );

    expect(dependencyChanges, 1);

    await tester.pumpWidget(
      _scopeTree(
        controller: secondController,
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
  required VoidCallback onDependencyChange,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: DialogScope(
      controller: controller,
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
