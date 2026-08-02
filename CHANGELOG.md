## 0.0.1

* Initial public release of `dialog_flow`.
* Added `DialogController` for dialog queueing, ordering, dismissal, and typed outcomes.
* Added `DialogHost` and `DialogScope` for app-wide and scoped dialog rendering.
* Added custom dialog widget support through `DialogRequest.widgetBuilder`.
* Added `DialogOutcome<T>` for confirmed, cancelled, and dismissed dialog results.
* Added `orderingData` and pluggable `DialogOrderStrategy` support for domain-specific ordering.
* Added example integrations for Riverpod and Flutter BLoC.
* Added unit and widget test coverage for controller, scope, host, and example behavior.
