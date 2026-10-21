## Unreleased

* **Breaking:** Require unique queued dialog IDs. All enqueue methods reject duplicates with `ArgumentError`. IDs may be reused after removal.
* **Breaking:** Remove `replaceAll()` in favor of `replace(handle, request)` for updating one queued entry while preserving its handle, pending outcome, and tie order. ID collisions leave the queue unchanged.
* **Breaking:** Remove `orderingData`, `DialogOrderStrategy`, `defaultDialogOrderStrategy`, and the controller's `orderStrategy` parameter. Dialogs now use descending numeric priority only, with insertion order for ties.
* Bind dialog dismissal callbacks and transition keys to queued-entry handles so stale UI events cannot dismiss a different dialog, including when a removed ID is reused.
* Add `DialogController.currentHandle()` to identify the active queued entry.

## 0.1.1

* Remove Broken API Documentation Links

## 0.1.0

* Initial public release of `dialog_controller`.
* Added `DialogController` for dialog queueing, ordering, dismissal, and typed outcomes.
* Added `DialogHost` and `DialogScope` for app-wide and scoped dialog rendering.
* Added custom dialog widget support through `DialogRequest.widgetBuilder`.
* Added `DialogOutcome<T>` for confirmed, cancelled, and dismissed dialog results.
* Added `orderingData` and pluggable `DialogOrderStrategy` support for domain-specific ordering.
* Added example integrations for Riverpod and Flutter BLoC.
* Added unit and widget test coverage for controller, scope, host, and example behavior.
* Added a table of contents to the README for faster navigation of package documentation.
* Added automated Dart API documentation publishing to GitHub Pages.
* Updated package metadata and README to point to hosted API docs.