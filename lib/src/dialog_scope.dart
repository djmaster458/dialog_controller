import 'package:flutter/widgets.dart';

import 'dialog_controller.dart';

/// Provides a dialog controller to descendants.
class DialogScope extends InheritedWidget {
  /// Creates a dialog controller provider scope.
  const DialogScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The controller shared by this subtree.
  final DialogController controller;

  /// Returns the nearest dialog scope.
  static DialogScope of(BuildContext context) {
    final DialogScope? scope = context.dependOnInheritedWidgetOfExactType<DialogScope>();
    assert(scope != null, 'No DialogScope found in context.');
    return scope!;
  }

  /// Returns the nearest controller.
  static DialogController controllerOf(BuildContext context) => of(context).controller;

  @override
  bool updateShouldNotify(DialogScope oldWidget) {
    return controller != oldWidget.controller;
  }
}