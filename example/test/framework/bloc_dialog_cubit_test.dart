import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/framework/bloc_dialog_cubit.dart';

void main() {
  test('queueHighPriority emits expected signal', () {
    final BlocDialogCubit cubit = BlocDialogCubit();

    cubit.queueHighPriority();

    final BlocDialogSignal? state = cubit.state;
    expect(state, isNotNull);
    expect(state!.priority, 40);
    expect(state.nonce, 1);
    expect(state.message, contains('high-priority'));
    expect(state.type, BlocDialogSignalType.message);

    cubit.close();
  });

  test('queueLowPriority increments nonce and emits low priority signal', () {
    final BlocDialogCubit cubit = BlocDialogCubit();

    cubit.queueHighPriority();
    cubit.queueLowPriority();

    final BlocDialogSignal? state = cubit.state;
    expect(state, isNotNull);
    expect(state!.priority, 2);
    expect(state.nonce, 2);
    expect(state.message, contains('low-priority'));
    expect(state.type, BlocDialogSignalType.message);

    cubit.close();
  });

  test('openPriorityControlDialog emits priority control signal', () {
    final BlocDialogCubit cubit = BlocDialogCubit();

    cubit.openPriorityControlDialog();

    final BlocDialogSignal? state = cubit.state;
    expect(state, isNotNull);
    expect(state!.priority, 20);
    expect(state.nonce, 1);
    expect(state.type, BlocDialogSignalType.priorityControl);
    expect(state.message, contains('priority-control dialog'));

    cubit.close();
  });
}
