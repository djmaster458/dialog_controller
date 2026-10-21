import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dialog_outcome.dart';
import 'dialog_request.dart';

/// Opaque handle returned when a request is enqueued.
///
/// Identifies one queued entry independently of [DialogRequest.id]. Reusing an
/// ID after removing its previous entry creates a distinct handle.
/// Use this handle only with the controller that created it.
class DialogRequestHandle {
  const DialogRequestHandle._(this._token);

  final int _token;
}

/// Result of enqueuing a request that is expected to resolve with an outcome.
class DialogOutcomeHandle<T> {
  const DialogOutcomeHandle({required this.handle, required this.outcome});

  /// Handle used to target this specific queued request.
  final DialogRequestHandle handle;

  /// Future resolved when the queued request is dismissed.
  final Future<DialogOutcome<T>> outcome;
}

/// Controls queued dialogs and exposes the currently eligible request.
///
/// Request IDs must be unique within this controller's queue. Higher priorities
/// are shown first, with insertion order preserved for equal priorities.
class DialogController extends ChangeNotifier {
  /// Creates a dialog controller.
  DialogController();

  final List<_QueuedDialog> _requests = <_QueuedDialog>[];
  final Map<int, Completer<DialogOutcome<Object?>>> _outcomeCompleters =
      <int, Completer<DialogOutcome<Object?>>>{};
  int _nextEntryToken = 0;

  /// Returns whether there are any queued dialogs.
  bool get hasRequests => _requests.isNotEmpty;

  /// Adds a request to the queue and returns an opaque request handle.
  ///
  /// Throws an [ArgumentError] if [DialogRequest.id] is already queued.
  /// Retain the returned handle for targeted dismissal.
  DialogRequestHandle enqueue(DialogRequest request) {
    final _QueuedDialog queuedRequest = _enqueueInternal(request);
    return queuedRequest.handle;
  }

  /// Adds a request and returns a typed dialog outcome.
  ///
  /// Throws an [ArgumentError] if [DialogRequest.id] is already queued.
  Future<DialogOutcome<T>> enqueueForOutcome<T>(DialogRequest request) {
    return enqueueForOutcomeWithHandle<T>(request).outcome;
  }

  /// Adds a request and returns both a request handle and typed outcome.
  ///
  /// Throws an [ArgumentError] if [DialogRequest.id] is already queued.
  DialogOutcomeHandle<T> enqueueForOutcomeWithHandle<T>(DialogRequest request) {
    _validateUniqueId(request.id);
    final _QueuedDialog queuedRequest = _createQueuedRequest(request);
    final Completer<DialogOutcome<Object?>> completer =
        Completer<DialogOutcome<Object?>>();
    _outcomeCompleters[queuedRequest.token] = completer;
    _requests.add(queuedRequest);
    notifyListeners();
    return DialogOutcomeHandle<T>(
      handle: queuedRequest.handle,
      outcome: completer.future.then((DialogOutcome<Object?> outcome) {
        return outcome.cast<T>();
      }),
    );
  }

  /// Adds a request and returns a future that completes when the dialog ends.
  ///
  /// Throws an [ArgumentError] if [DialogRequest.id] is already queued.
  Future<T?> enqueueForResult<T>(DialogRequest request) {
    return enqueueForOutcome<T>(request).then((DialogOutcome<T> outcome) {
      return outcome.value;
    });
  }

  /// Returns the queued requests.
  List<DialogRequest> requests() {
    final List<_QueuedDialog> filteredRequests = _sortedRequests();
    return List<DialogRequest>.unmodifiable(
      filteredRequests.map((_QueuedDialog request) => request.request),
    );
  }

  /// Returns the highest-priority request, if any.
  DialogRequest? current() {
    return _currentRequest()?.request;
  }

  /// Returns the handle of the highest-priority queued entry, if any.
  ///
  /// The handle remains stable for that entry, even if another request becomes
  /// current. Reusing an ID after removal creates a distinct handle.
  DialogRequestHandle? currentHandle() {
    return _currentRequest()?.handle;
  }

  /// Removes a request by handle.
  bool dismiss(DialogRequestHandle handle) {
    return dismissWithOutcome(handle, const DialogOutcome<Object?>.dismissed());
  }

  /// Removes a request by handle and resolves its pending outcome.
  /// Returns true if removed, or false for a stale or foreign handle.
  bool dismissWithOutcome(
    DialogRequestHandle handle, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final int index = _requests.indexWhere(
      (_QueuedDialog request) =>
          request.token == handle._token && identical(request.handle, handle),
    );
    if (index < 0) {
      return false;
    }

    final _QueuedDialog removedRequest = _requests.removeAt(index);
    _completeOutcome(removedRequest, outcome);
    notifyListeners();
    return true;
  }

  /// Removes the current request.
  /// Returns true if the request was found and removed, false otherwise.
  bool dismissCurrent() {
    return dismissCurrentWithOutcome(
      outcome: const DialogOutcome<Object?>.dismissed(),
    );
  }

  /// Removes the current request and resolves its pending outcome.
  /// Returns true if the request was found and removed, false otherwise.
  bool dismissCurrentWithOutcome({DialogOutcome<Object?>? outcome}) {
    final _QueuedDialog? activeRequest = _currentRequest();
    if (activeRequest == null) {
      return false;
    }

    return _dismissQueuedRequest(activeRequest, outcome);
  }

  /// Removes all queued requests.
  void clear() {
    if (_requests.isEmpty) {
      return;
    }

    final List<_QueuedDialog> removedRequests = List<_QueuedDialog>.from(
      _requests,
    );
    _requests.clear();
    _completeOutcomes(removedRequests);
    notifyListeners();
  }

  /// Replaces the request identified by [handle].
  ///
  /// Preserves the entry's handle, pending outcome, and insertion order for
  /// priority ties. Changing priority immediately updates queue ordering.
  /// The replacement may keep the original ID or use an ID not already queued.
  ///
  /// Returns false for a stale handle without changing the queue. Throws an
  /// [ArgumentError] if another entry already uses [DialogRequest.id], leaving
  /// the queue and pending outcomes unchanged. Use the originating controller.
  bool replace(DialogRequestHandle handle, DialogRequest request) {
    final int index = _requests.indexWhere(
      (_QueuedDialog entry) => identical(entry.handle, handle),
    );
    if (index < 0) {
      return false;
    }
    final _QueuedDialog existing = _requests[index];
    if (request.id != existing.request.id) {
      _validateUniqueId(request.id);
    }
    _requests[index] = _QueuedDialog(
      token: existing.token,
      handle: existing.handle,
      request: request,
    );
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _completeOutcomes(_requests);
    _requests.clear();
    super.dispose();
  }

  _QueuedDialog _enqueueInternal(DialogRequest request) {
    _validateUniqueId(request.id);
    final _QueuedDialog queuedRequest = _createQueuedRequest(request);

    _requests.add(queuedRequest);
    notifyListeners();
    return queuedRequest;
  }

  void _validateUniqueId(String id) {
    if (_requests.any((_QueuedDialog entry) => entry.request.id == id)) {
      throw ArgumentError.value(id, 'id', 'Dialog ID is already queued');
    }
  }

  void _completeOutcomes(
    Iterable<_QueuedDialog> requests, [
    DialogOutcome<Object?>? outcome,
  ]) {
    for (final _QueuedDialog request in requests) {
      _completeOutcome(request, outcome);
    }
  }

  void _completeOutcome(
    _QueuedDialog request, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final Completer<DialogOutcome<Object?>>? completer = _outcomeCompleters
        .remove(request.token);
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome ?? const DialogOutcome<Object?>.dismissed());
    }
  }

  List<_QueuedDialog> _allRequests() {
    return List<_QueuedDialog>.from(_requests);
  }

  _QueuedDialog? _currentRequest() {
    final List<_QueuedDialog> filteredRequests = _sortedRequests();
    if (filteredRequests.isEmpty) {
      return null;
    }

    return filteredRequests.first;
  }

  bool _dismissQueuedRequest(
    _QueuedDialog request, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final int index = _requests.indexWhere(
      (_QueuedDialog candidate) => candidate.token == request.token,
    );
    if (index < 0) {
      return false;
    }

    final _QueuedDialog removedRequest = _requests.removeAt(index);
    _completeOutcome(removedRequest, outcome);
    notifyListeners();
    return true;
  }

  _QueuedDialog _createQueuedRequest(DialogRequest request) {
    final int token = _nextEntryToken++;
    return _QueuedDialog(
      token: token,
      handle: DialogRequestHandle._(token),
      request: request,
    );
  }

  List<_QueuedDialog> _sortedRequests() {
    final List<_QueuedDialog> filteredRequests = _allRequests();
    filteredRequests.sort((_QueuedDialog a, _QueuedDialog b) {
      final int result = b.request.priority.compareTo(a.request.priority);
      if (result != 0) {
        return result;
      }

      return a.token.compareTo(b.token);
    });
    return filteredRequests;
  }
}

class _QueuedDialog {
  const _QueuedDialog({
    required this.token,
    required this.handle,
    required this.request,
  });

  final int token;
  final DialogRequestHandle handle;
  final DialogRequest request;
}
