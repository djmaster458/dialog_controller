import 'package:flutter/material.dart';

import 'dialog_controller.dart';
import 'dialog_request.dart';
import 'dialog_scope.dart';

/// Builds a dialog surface for the active request.
typedef DialogContentBuilder = DialogWidgetBuilder;

/// Hosts the dialog layer above a child subtree.
class DialogHost extends StatelessWidget {
  /// Creates a dialog host.
  const DialogHost({
    super.key,
    required this.child,
    required this.builder,
    this.controller,
    this.scopeId,
    this.barrierColor = const Color(0x8A000000),
    this.barrierDismissible = true,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.all(24),
    this.transitionDuration = const Duration(milliseconds: 200),
  });

  /// The child placed below the dialog layer.
  final Widget child;

  /// Builds the visible dialog for the current request.
  final DialogContentBuilder builder;

  /// The controller that drives the host.
  final DialogController? controller;

  /// The scope used to select requests.
  final String? scopeId;

  /// The modal barrier color.
  final Color barrierColor;

  /// Whether tapping the barrier dismisses the current dialog.
  final bool barrierDismissible;

  /// The alignment used to position the dialog content.
  final Alignment alignment;

  /// Padding applied around the dialog content.
  final EdgeInsets padding;

  /// The animation duration when the active dialog changes.
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final DialogController resolvedController = controller ?? DialogScope.controllerOf(context);
    final String? resolvedScopeId = scopeId ?? DialogScope.scopeIdOf(context);

    return AnimatedBuilder(
      animation: resolvedController,
      builder: (BuildContext context, Widget? _) {
        final DialogRequest? request = resolvedController.current(scopeId: resolvedScopeId);
        final Widget overlay = request == null
            ? const SizedBox.shrink()
            : _DialogOverlay(
                request: request,
                builder: builder,
                barrierColor: barrierColor,
                barrierDismissible: barrierDismissible,
                alignment: alignment,
                padding: padding,
                transitionDuration: transitionDuration,
                onDismiss: ([outcome]) {
                  resolvedController.dismissWithOutcome(request.id, outcome);
                },
              );

        return Stack(
          children: <Widget>[
            child,
            overlay,
          ],
        );
      },
    );
  }
}

class _DialogOverlay extends StatelessWidget {
  const _DialogOverlay({
    required this.request,
    required this.builder,
    required this.barrierColor,
    required this.barrierDismissible,
    required this.alignment,
    required this.padding,
    required this.transitionDuration,
    required this.onDismiss,
  });

  final DialogRequest request;
  final DialogContentBuilder builder;
  final Color barrierColor;
  final bool barrierDismissible;
  final Alignment alignment;
  final EdgeInsets padding;
  final Duration transitionDuration;
  final DialogDismissCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final DialogContentBuilder resolvedBuilder = request.widgetBuilder ?? builder;

    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: transitionDuration,
        child: Container(
          key: ValueKey<String>(request.id),
          color: barrierColor,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (barrierDismissible)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: const SizedBox.expand(),
                ),
              Align(
                alignment: alignment,
                child: Padding(
                  padding: padding,
                  child: resolvedBuilder(context, request, onDismiss),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}