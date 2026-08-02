import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dialog_controller/dialog_controller.dart';

final Provider<DialogController> dialogControllerProvider =
    Provider<DialogController>((Ref ref) {
      final DialogController controller = DialogController();
      ref.onDispose(controller.dispose);
      return controller;
    });
