# dialog_controller example

This example application demonstrates how to use `dialog_controller` for:

- app-wide dialog orchestration
- handle-based request targeting (`enqueue` + `dismiss`)
- updating a single queued dialog (`replace` + `copyWith`)
- custom dialog widgets with typed outcomes
- handle-aware outcomes via `enqueueForOutcomeWithHandle<T>()`
- numeric priority ordering flows
- Riverpod integration using a provided `DialogController`
- Flutter BLoC integration using `BlocListener`

## Queue IDs and priority

Each `DialogRequest.id` must be unique among requests currently queued in the
same controller. Enqueuing a duplicate ID throws `ArgumentError`; an ID may be
reused after its request is removed. Separate controllers may use the same IDs.

The Core API and Riverpod demos generate a new ID for every request using a
descriptive prefix and a page-state monotonic counter (`_nextRequestId`). The
BLoC demo uses its Cubit's existing monotonic signal nonce. Repeated clicks,
including multiple lower-priority requests queued inside an open priority
dialog, therefore create distinct entries rather than colliding on fixed IDs.

Ordering uses only numeric `priority`, with higher values shown first. IDs do not
affect ordering, so their prefixes and generated suffixes are only identifiers.

## Updating a queued dialog

In the Core API section, select **Queue replaceable dialog**, then **Update** in
the snackbar. The example captures the handle returned by `enqueue` and calls
`controller.replace(handle, request.copyWith(payload: ...))` to update that
entry's content. Its ID is generated with the existing `_nextRequestId` counter,
so repeated uses enqueue distinct entries.

`replace` preserves the handle, original insertion position for priority ties,
and any pending outcome. It returns `false` if the handle is stale, so a delayed
Update cannot replace another dialog after the original entry is dismissed.
Changing the ID to one owned by another queued entry throws `ArgumentError`.
This targets one entry; the previous `replaceAll` API has been removed.

Run the example from the repository root:

```bash
cd example
fvm flutter run
```
