# dialog_controller

An out-of-the-box Dialog system for apps with complex dialog flows.

This package separates dialog coordination from dialog rendering:

- `DialogController` manages queueing, priority, and dismissal.
- `DialogHost` renders the active dialog layer in the widget tree.
- `DialogScope` provides a controller to descendants.
- `DialogRequest.widgetBuilder` lets each feature provide a custom dialog widget.
- `enqueueForOutcome<T>()` returns a formal typed outcome model.

The package uses only first-party Flutter and Dart dependencies for portability.

## Table of Contents

- [Why use this package](#why-use-this-package)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
	- [1. Queue requests with priority](#1-queue-requests-with-priority)
	- [1.1 Replace a specific request](#11-replace-a-specific-request)
	- [2. Render dialogs through a host](#2-render-dialogs-through-a-host)
	- [2.1 Queue a feature-owned custom widget](#21-queue-a-feature-owned-custom-widget)
	- [2.2 Await dialog outcomes](#22-await-dialog-outcomes)
- [Custom overlay](#custom-overlay)

## Why use this package

- Avoids `showDialog` and `Navigator.pop` limitations.
- Supports multiple dialogs with deterministic ordering.
- Uses a simple one-overlay-per-controller model.
- Exposes interfaces (`ChangeNotifier`, callbacks, payload data) that are easy to bridge into Riverpod, BLoC, or custom state management systems.

## Installation

Add the dependency:

```yaml
dependencies:
	dialog_controller: ^0.1.1
```

## Core Concepts

### 1. Queue requests with priority

```dart
final controller = DialogController();

controller.enqueue(
  const DialogRequest(
    id: 'network-alert',
    priority: 100,
    payload: 'Connection lost.',
  ),
);

final DialogRequestHandle handle = controller.enqueue(
  const DialogRequest(
    id: 'network-alert-follow-up',
    priority: 80,
    payload: 'Retry connection?',
  ),
);

controller.dismiss(handle);
```

Higher `priority` values win. Requests with equal priority keep insertion order.

**Each queued dialog must have a unique `DialogRequest.id` within its controller.**
All enqueue methods throw `ArgumentError` if the ID is already queued, including
when the same request object is enqueued twice. Requests are never silently
replaced or deduplicated. Replacing a specific request also rejects an ID used
by another entry without changing the queue or pending outcomes.

An ID can be reused after removal, and separate controllers can use the same ID.
Use distinct IDs when queueing multiple instances of the same dialog, such as
`'network-alert-$sequence'`. Priority is the only ordering input; higher numbers
appear first, including when priorities are negative. Equal priorities retain
insertion order. There is no custom ordering strategy or ordering metadata.

Retain the `DialogRequestHandle` returned by `enqueue()` (or the `handle` on
`enqueueForOutcomeWithHandle<T>()`'s return value) for targeted dismissal on the
**same controller**. Handles identify a particular enqueue operation, so a stale
callback cannot dismiss a new dialog that reuses a removed ID. Dismissing a stale
handle returns `false`. Dialog widgets can simply use the host's `dismiss`
callback, which captures the correct handle automatically.

### 1.1 Replace a specific request

```dart
final request = DialogRequest(id: 'sync-status', payload: 'Syncing...');
final handle = controller.enqueue(request);

final bool replaced = controller.replace(
  handle,
  request.copyWith(payload: 'Sync complete.', priority: 10),
);
```

`replace(handle, request)` updates only the targeted entry. It preserves the
handle, any pending outcome future, and the original insertion order for priority
ties. Changing priority immediately reorders the queue. The replacement may keep
its ID or use a new unique ID; a renamed entry releases its previous ID.

The method returns `false` for a stale handle and throws `ArgumentError` if the
new ID belongs to another queued entry. Other requests remain unchanged. Use the
controller that created the handle. Bulk queue replacement is not supported.

### 2. Render dialogs through a host

```dart
MaterialApp(
  home: DialogScope(
    controller: controller,
    child: DialogHost(
      builder: (context, request, dismiss) {
        return AlertDialog(
          title: const Text('Dialog'),
          content: Text('${request.payload}'),
          actions: [
            TextButton(onPressed: dismiss, child: const Text('Close')),
          ],
        );
      },
      child: const HomeScreen(),
    ),
  ),
);
```

The host-level `builder` is a default builder for the `Dialog`. Any request can override it by providing `widgetBuilder`. The `DialogHost` manages the overlay.

### 2.1 Queue a feature-owned custom widget

```dart
controller.enqueue(
  DialogRequest(
    id: 'billing-upgrade',
    priority: 50,
    widgetBuilder: (context, request, dismiss) {
      return UpgradeDialog(onDismiss: dismiss);
    },
  ),
);
```

### 2.2 Await dialog outcomes

```dart
final DialogOutcome<bool> outcome = await controller.enqueueForOutcome<bool>(
  DialogRequest(
    id: 'delete-confirmation',
    widgetBuilder: (context, request, dismiss) {
      return AlertDialog(
        title: const Text('Delete item?'),
        actions: [
          TextButton(
            onPressed: () => dismiss(const DialogOutcome<Object?>.cancelled(false)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => dismiss(const DialogOutcome<Object?>.confirmed(true)),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  ),
);

if (outcome.isConfirmed && outcome.value == true) {
  // Proceed with deletion.
}
```

Use `dismiss()` without an argument for a neutral close. The returned type is
`DialogOutcomeType.dismissed`.

`enqueueForResult<T>()` is still available if you only need the payload value
without outcome metadata.

## Custom overlay

`DialogHost` is the default overlay implementation, but you can build your own
overlay widget if you want different transitions, hit testing, layering, or
placement behavior.

The package responsibilities stay the same:

- `DialogController` decides which request is active.
- `DialogScope` provides the controller.
- Your custom overlay decides how to render and dismiss the active request.

Minimal pattern:

```dart
class CustomDialogOverlay extends StatelessWidget {
  const CustomDialogOverlay({
    super.key,
    required this.child,
    required this.builder,
    this.controller,
  });

  final Widget child;
  final DialogWidgetBuilder builder;
  final DialogController? controller;

  @override
  Widget build(BuildContext context) {
    // Alternative: Inject with GetX, Riverpod, or other providers
    final DialogController resolvedController =
        controller ?? DialogScope.controllerOf(context);

    return AnimatedBuilder(
      animation: resolvedController,
      builder: (context, _) {
        final DialogRequest? request = resolvedController.current();
        final DialogRequestHandle? handle = resolvedController.currentHandle();

        return Stack(
          children: [
            child,
            if (request != null && handle != null)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x66000000),
                  child: Center(
                    child: builder(
                      context,
                      request,
                      ([outcome]) => resolvedController.dismissWithOutcome(
                        handle,
                        outcome,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

## Example app

The repository includes a full example application under `example/` showing:

- global dialogs
- custom widget dialogs with outcomes
- Riverpod-provided `DialogController` usage
- Flutter BLoC integration via listener-driven requests
- interactive priority control dialogs
