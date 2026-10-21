import 'package:flutter/widgets.dart';

import 'dialog_outcome.dart';

/// Callback used by dialog widgets to dismiss with an optional outcome value.
typedef DialogDismissCallback =
    void Function([DialogOutcome<Object?>? outcome]);

/// Builds a custom dialog widget for a queued request.
typedef DialogWidgetBuilder =
    Widget Function(
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
    this.priority = 0,
    this.widgetBuilder,
  });

  /// Unique identifier within a controller's queue.
  ///
  /// Enqueuing an ID that is already queued throws an [ArgumentError]. The ID
  /// can be reused after its previous request is removed. Retain the entry's
  /// `DialogRequestHandle` for dismissal callbacks that may outlive that entry.
  final String id;

  /// Optional payload that the UI layer can use to render content.
  final Object? payload;

  /// Higher values are shown first; equal priorities keep insertion order.
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
    int? priority,
    DialogWidgetBuilder? widgetBuilder,
  }) {
    return DialogRequest(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      widgetBuilder: widgetBuilder ?? this.widgetBuilder,
    );
  }
}
