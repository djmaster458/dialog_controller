/// Represents how a dialog completed, with an optional typed payload.
class DialogOutcome<T> {
  /// Creates a dialog outcome.
  const DialogOutcome._(this.type, this.value);

  /// Creates a confirmed outcome.
  const DialogOutcome.confirmed([T? value])
    : this._(DialogOutcomeType.confirmed, value);

  /// Creates a cancelled outcome.
  const DialogOutcome.cancelled([T? value])
    : this._(DialogOutcomeType.cancelled, value);

  /// Creates a dismissed outcome.
  const DialogOutcome.dismissed([T? value])
    : this._(DialogOutcomeType.dismissed, value);

  /// How the dialog completed.
  final DialogOutcomeType type;

  /// Optional typed payload returned by the dialog.
  final T? value;

  /// Returns true when the dialog completed with confirmation.
  bool get isConfirmed => type == DialogOutcomeType.confirmed;

  /// Returns true when the dialog completed with cancellation.
  bool get isCancelled => type == DialogOutcomeType.cancelled;

  /// Returns true when the dialog completed via neutral dismissal.
  bool get isDismissed => type == DialogOutcomeType.dismissed;

  /// Casts this outcome payload type.
  DialogOutcome<R> cast<R>() {
    return DialogOutcome<R>._(type, value as R?);
  }
}

/// Enumerates dialog completion states.
enum DialogOutcomeType {
  /// User or flow confirmed the dialog action.
  confirmed,

  /// User or flow cancelled the dialog action.
  cancelled,

  /// Dialog was dismissed without explicit confirm/cancel intent.
  dismissed,
}