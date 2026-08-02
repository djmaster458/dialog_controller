import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dialog/flutter_dialog.dart';

final Provider<DialogController> dialogControllerProvider =
    Provider<DialogController>((Ref ref) {
      final DialogController controller = DialogController();
      ref.onDispose(controller.dispose);
      return controller;
    });
