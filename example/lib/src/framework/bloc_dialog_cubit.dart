import 'package:flutter_bloc/flutter_bloc.dart';

enum BlocDialogSignalType {
  message,
  priorityControl,
}

class BlocDialogSignal {
  const BlocDialogSignal({
    required this.nonce,
    required this.priority,
    required this.message,
    this.type = BlocDialogSignalType.message,
  });

  final int nonce;
  final int priority;
  final String message;
  final BlocDialogSignalType type;
}

class BlocDialogCubit extends Cubit<BlocDialogSignal?> {
  BlocDialogCubit() : super(null);

  int _nonce = 0;

  void queueHighPriority() {
    emit(
      BlocDialogSignal(
        nonce: ++_nonce,
        priority: 40,
        message:
            'BLoC integration: emitted high-priority dialog signal from Cubit.',
      ),
    );
  }

  void queueLowPriority() {
    emit(
      BlocDialogSignal(
        nonce: ++_nonce,
        priority: 2,
        message: 'BLoC integration: emitted low-priority dialog signal from Cubit.',
      ),
    );
  }

  void openPriorityControlDialog() {
    emit(
      BlocDialogSignal(
        nonce: ++_nonce,
        priority: 20,
        message:
            'BLoC integration: open priority-control dialog to queue higher or lower follow-up dialogs.',
        type: BlocDialogSignalType.priorityControl,
      ),
    );
  }
}
