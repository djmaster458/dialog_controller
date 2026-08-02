import 'package:flutter/widgets.dart';

import 'dialog_controller.dart';

/// Provides a dialog controller and default scope to descendants.
class DialogScope extends InheritedWidget {
  /// Creates a dialog scope.
  const DialogScope({
    super.key,
    required this.controller,
    this.scopeId,
    required super.child,
  });

  /// The controller shared by this subtree.
  final DialogController controller;

  /// The default scope used by descendants.
  final String? scopeId;

  /// Returns the nearest dialog scope.
  static DialogScope of(BuildContext context) {
    final DialogScope? scope = context.dependOnInheritedWidgetOfExactType<DialogScope>();
    assert(scope != null, 'No DialogScope found in context.');
    return scope!;
  }

  /// Returns the nearest controller.
  static DialogController controllerOf(BuildContext context) => of(context).controller;

  /// Returns the nearest default scope.
  static String? scopeIdOf(BuildContext context) => of(context).scopeId;

  @override
  bool updateShouldNotify(DialogScope oldWidget) {
    return controller != oldWidget.controller || scopeId != oldWidget.scopeId;
  }
}