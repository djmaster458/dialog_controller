# dialog_controller example

This example application demonstrates how to use `dialog_controller` for:

- app-wide dialog orchestration
- handle-based request targeting (`enqueue` + `dismiss`)
- custom dialog widgets with typed outcomes
- handle-aware outcomes via `enqueueForOutcomeWithHandle<T>()`
- custom priority ordering flows
- Riverpod integration using a provided `DialogController`
- Flutter BLoC integration using `BlocListener`

Run the example from the repository root:

```bash
cd example
fvm flutter run
```
