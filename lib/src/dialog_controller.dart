import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dialog_outcome.dart';
import 'dialog_request.dart';

/// Controls queued dialogs and exposes the currently eligible request.
class DialogController extends ChangeNotifier {
  /// Creates a dialog controller.
  DialogController({DialogOrderStrategy? orderStrategy})
    : _orderStrategy = orderStrategy ?? defaultDialogOrderStrategy;

  final DialogOrderStrategy _orderStrategy;
  final List<DialogRequest> _requests = <DialogRequest>[];
    final Map<int, Completer<DialogOutcome<Object?>>> _outcomeCompleters =
      <int, Completer<DialogOutcome<Object?>>>{};
  int _nextSequence = 0;

  /// Returns whether there are any queued dialogs.
  bool get hasRequests => _requests.isNotEmpty;

  /// Adds a request to the queue and returns its identifier.
  String enqueue(DialogRequest request) {
    final DialogRequest queuedRequest = _enqueueInternal(request);
    return queuedRequest.id;
  }

  /// Adds a request and returns a typed dialog outcome.
  Future<DialogOutcome<T>> enqueueForOutcome<T>(DialogRequest request) {
    final DialogRequest queuedRequest = _enqueueInternal(request);
    final Completer<DialogOutcome<Object?>> completer =
        Completer<DialogOutcome<Object?>>();
    _outcomeCompleters[queuedRequest.sequence] = completer;
    return completer.future.then((DialogOutcome<Object?> outcome) {
      return outcome.cast<T>();
    });
  }

  /// Adds a request and returns a future that completes when the dialog ends.
  Future<T?> enqueueForResult<T>(DialogRequest request) {
    return enqueueForOutcome<T>(request).then((DialogOutcome<T> outcome) {
      return outcome.value;
    });
  }

  /// Returns the queued requests, optionally filtered by scope.
  List<DialogRequest> requests({String? scopeId}) {
    final List<DialogRequest> filteredRequests = _filterByScope(scopeId);
    filteredRequests.sort(_orderStrategy);
    return List<DialogRequest>.unmodifiable(filteredRequests);
  }

  /// Returns the highest-priority request for the provided scope.
  DialogRequest? current({String? scopeId}) {
    final List<DialogRequest> filteredRequests = requests(scopeId: scopeId);
    if (filteredRequests.isEmpty) {
      return null;
    }

    return filteredRequests.first;
  }

  /// Removes a request by identifier.
  bool dismiss(String id) {
    return dismissWithOutcome(id, const DialogOutcome<Object?>.dismissed());
  }

  /// Removes a request by identifier and resolves its pending outcome.
  bool dismissWithOutcome(String id, [DialogOutcome<Object?>? outcome]) {
    final int index = _requests.indexWhere((DialogRequest request) => request.id == id);
    if (index < 0) {
      return false;
    }

    final DialogRequest removedRequest = _requests.removeAt(index);
    _completeOutcome(removedRequest, outcome);
    notifyListeners();
    return true;
  }

  /// Removes a request by sequence identifier and resolves its outcome.
  bool dismissBySequenceWithOutcome(
    int sequence, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final int index = _requests.indexWhere((DialogRequest request) => request.sequence == sequence);
    if (index < 0) {
      return false;
    }

    final DialogRequest removedRequest = _requests.removeAt(index);
    _completeOutcome(removedRequest, outcome);
    notifyListeners();
    return true;
  }

  /// Removes the current request for a scope.
  bool dismissCurrent({String? scopeId}) {
    return dismissCurrentWithOutcome(
      scopeId: scopeId,
      outcome: const DialogOutcome<Object?>.dismissed(),
    );
  }

  /// Removes the current request for a scope and resolves its pending outcome.
  bool dismissCurrentWithOutcome({
    String? scopeId,
    DialogOutcome<Object?>? outcome,
  }) {
    final DialogRequest? activeRequest = current(scopeId: scopeId);
    if (activeRequest == null) {
      return false;
    }

    return dismissBySequenceWithOutcome(activeRequest.sequence, outcome);
  }

  /// Removes all queued requests, optionally limited to a scope.
  void clear({String? scopeId}) {
    final List<DialogRequest> removedRequests;
    if (scopeId == null) {
      if (_requests.isEmpty) {
        return;
      }

      removedRequests = List<DialogRequest>.from(_requests);
      _requests.clear();
      _completeOutcomes(removedRequests);
      notifyListeners();
      return;
    }

    removedRequests = <DialogRequest>[];
    _requests.removeWhere((DialogRequest request) {
      final bool match = request.scopeId == scopeId;
      if (match) {
        removedRequests.add(request);
      }
      return match;
    });

    if (removedRequests.isNotEmpty) {
      _completeOutcomes(removedRequests);
      notifyListeners();
    }
  }

  /// Replaces the queue with a new list of requests.
  void replaceAll(Iterable<DialogRequest> requests) {
    final List<DialogRequest> removedRequests = List<DialogRequest>.from(
      _requests,
    );
    _requests
      ..clear()
      ..addAll(
        requests.map(
          (DialogRequest request) => request.copyWith(sequence: _nextSequence++),
        ),
      );
    _completeOutcomes(removedRequests);
    notifyListeners();
  }

  @override
  void dispose() {
    _completeOutcomes(_requests);
    _requests.clear();
    super.dispose();
  }

  DialogRequest _enqueueInternal(DialogRequest request) {
    final int initialLength = _requests.length;
    final DialogRequest queuedRequest = request.copyWith(
      sequence: _nextSequence++,
    );

    _requests.add(queuedRequest);
    if (_requests.length != initialLength) {
      notifyListeners();
    }
    return queuedRequest;
  }

  void _completeOutcomes(
    Iterable<DialogRequest> requests, [
    DialogOutcome<Object?>? outcome,
  ]) {
    for (final DialogRequest request in requests) {
      _completeOutcome(request, outcome);
    }
  }

  void _completeOutcome(
    DialogRequest request, [
    DialogOutcome<Object?>? outcome,
  ]) {
    final Completer<DialogOutcome<Object?>>? completer = _outcomeCompleters.remove(
      request.sequence,
    );
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        outcome ?? const DialogOutcome<Object?>.dismissed(),
      );
    }
  }

  List<DialogRequest> _filterByScope(String? scopeId) {
    if (scopeId == null) {
      return List<DialogRequest>.from(_requests.where((DialogRequest request) => request.scopeId == null));
    }

    return List<DialogRequest>.from(
      _requests.where((DialogRequest request) => request.scopeId == scopeId),
    );
  }
}