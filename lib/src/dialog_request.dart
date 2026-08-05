import 'package:flutter/widgets.dart';

import 'dialog_outcome.dart';

/// Callback used by dialog widgets to dismiss with an optional outcome value.
typedef DialogDismissCallback =
  void Function([DialogOutcome<Object?>? outcome]);

/// Builds a custom dialog widget for a queued request.
typedef DialogWidgetBuilder = Widget Function(
  BuildContext context,
  DialogRequest request,
  DialogDismissCallback dismiss,
);

/// Immutable dialog data used by [DialogController] and [DialogHost].
class DialogRequest {
  /// Creates a dialog request.
  const DialogRequest({
    required this.id,
    this.payload,
    this.orderingData,
    this.priority = 0,
    this.widgetBuilder,
  });

  /// Stable identifier for the request.
  final String id;

  /// Optional payload that the UI layer can use to render content.
  final Object? payload;

  /// Optional metadata used by custom ordering strategies.
  ///
  /// This lets callers provide comparison-specific data without overloading
  /// [payload], which is intended for rendering concerns.
  final Object? orderingData;

  /// Higher values are shown before lower values by the default strategy.
  /// May be used by the custom ordering strategy to determine the order of requests in the queue.
  final int priority;

  /// Optional request-level widget builder.
  ///
  /// When provided, [DialogHost] uses this builder instead of its host-level
  /// builder, allowing callers to render fully custom dialog widgets per
  /// request while still using the same queue architecture.
  final DialogWidgetBuilder? widgetBuilder;

  /// Creates a copy of this request with updated values.
  DialogRequest copyWith({
    String? id,
    Object? payload,
    Object? orderingData,
    int? priority,
    DialogWidgetBuilder? widgetBuilder,
  }) {
    return DialogRequest(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      orderingData: orderingData ?? this.orderingData,
      priority: priority ?? this.priority,
      widgetBuilder: widgetBuilder ?? this.widgetBuilder,
    );
  }
}

/// Compares two dialog requests and returns an ordering result.
typedef DialogOrderStrategy = int Function(
  DialogRequest a,
  DialogRequest b,
);

/// Orders higher-priority dialogs first.
///
/// When this comparator returns `0`, [DialogController] preserves insertion
/// order for deterministic tie-breaking.
int defaultDialogOrderStrategy(DialogRequest a, DialogRequest b) {
  return b.priority.compareTo(a.priority);
}