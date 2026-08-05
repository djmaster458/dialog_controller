import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dialog_outcome.dart';
import 'dialog_request.dart';

/// Opaque handle returned when a request is enqueued.
class DialogRequestHandle {
  const DialogRequestHandle._(this._token);

  final int _token;
}

/// Result of enqueuing a request that is expected to resolve with an outcome.
class DialogOutcomeHandle<T> {
  const DialogOutcomeHandle({
    required this.handle,
    required this.outcome,
  });

  /// Handle used to target this specific queued request.
  final DialogRequestHandle handle;

  /// Future resolved when the queued request is dismissed.
  final Future<DialogOutcome<T>> outcome;
}

/// Controls queued dialogs and exposes the currently eligible request.
class DialogController extends ChangeNotifier {
  /// Creates a dialog controller.
  DialogController({DialogOrderStrategy? orderStrategy})
    : _orderStrategy = orderStrategy ?? defaultDialogOrderStrategy;

  final DialogOrderStrategy _orderStrategy;
  final List<_QueuedDialog> _requests = <_QueuedDialog>[];
  final Map<int, Completer<DialogOutcome<Object?>>> _outcomeCompleters =
      <int, Completer<DialogOutcome<Object?>>>{};
  int _nextEntryToken = 0;

  /// Returns whether there are any queued dialogs.
  bool get hasRequests => _requests.isNotEmpty;

  /// Adds a request to the queue and returns an opaque request handle.
  DialogRequestHandle enqueue(DialogRequest request) {
    final _QueuedDialog queuedRequest = _enqueueInternal(request);
    return queuedRequest.handle;
  }

  /// Adds a request and returns a typed dialog outcome.
  Future<DialogOutcome<T>> enqueueForOutcome<T>(DialogRequest request) {
    return enqueueForOutcomeWithHandle<T>(request).outcome;
  }

  /// Adds a request and returns both a request handle and typed outcome.
  DialogOutcomeHandle<T> enqueueForOutcomeWithHandle<T>(
    DialogRequest request,
  ) {
    final _QueuedDialog queuedRequest = _enqueueInternal(request);
    final Completer<DialogOutcome<Object?>> completer =
        Completer<DialogOutcome<Object?>>();
    _outcomeCompleters[queuedRequest.token] = completer;
    return DialogOutcomeHandle<T>(
      handle: queuedRequest.handle,
      outcome: completer.future.then((DialogOutcome<Object?> outcome) {
        return outcome.cast<T>();
      }),
    );
  }

  /// Adds a request and returns a future that completes when the dialog ends.
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

  /// Removes a request by handle.
  bool dismiss(DialogRequestHandle handle) {
    return dismissWithOutcome(
      handle,
      const DialogOutcome<Object?>.dismissed(),
    );
  }

  /// Removes a request by handle and resolves its pending outcome.
  /// Returns true if the request was found and removed, false otherwise.
  bool dismissWithOutcome(
    DialogRequestHandle handle, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final int index = _requests.indexWhere(
      (_QueuedDialog request) => request.token == handle._token,
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
  bool dismissCurrentWithOutcome({
    DialogOutcome<Object?>? outcome,
  }) {
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

  /// Replaces the queue with a new list of requests.
  void replaceAll(Iterable<DialogRequest> requests) {
    final List<_QueuedDialog> removedRequests = List<_QueuedDialog>.from(
      _requests,
    );
    _requests
      ..clear()
      ..addAll(requests.map(_createQueuedRequest));
    _completeOutcomes(removedRequests);
    notifyListeners();
  }

  @override
  void dispose() {
    _completeOutcomes(_requests);
    _requests.clear();
    super.dispose();
  }

  _QueuedDialog _enqueueInternal(DialogRequest request) {
    final int initialLength = _requests.length;
    final _QueuedDialog queuedRequest = _createQueuedRequest(request);

    _requests.add(queuedRequest);
    if (_requests.length != initialLength) {
      notifyListeners();
    }
    return queuedRequest;
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
    final Completer<DialogOutcome<Object?>>? completer = _outcomeCompleters.remove(
      request.token,
    );
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        outcome ?? const DialogOutcome<Object?>.dismissed(),
      );
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
      final int result = _orderStrategy(a.request, b.request);
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