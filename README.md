# flutter_dialog

An out-of-the-box Dialog system for apps with complex dialog flows.

This package separates dialog coordination from dialog rendering:

- `DialogController` manages queueing, priority, and dismissal.
- `DialogHost` renders the active dialog layer in the widget tree.
- `DialogScope` isolates dialog traffic for specific subtrees.
- `DialogRequest.widgetBuilder` lets each feature provide a custom dialog widget.
- `enqueueForOutcome<T>()` returns a formal typed outcome model.

The package uses only first-party Flutter and Dart dependencies for portability.

## Why use this package

- Avoids `showDialog` and `Navigator.pop` flows
- Supports multiple dialogs with deterministic ordering.
- Supports subtree scoping so independent areas of UI can host their own dialogs.
- Exposes interfaces (`ChangeNotifier`, callbacks, payload data) that are easy to bridge into Riverpod, BLoC, or custom state management systems

## Installation

Add the dependency:

```yaml
dependencies:
	flutter_dialog: ^0.0.1
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
```

Higher `priority` values win. Requests with equal priority keep insertion order.

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

The host-level `builder` is a fallback renderer. Any request can override it by
providing `widgetBuilder`.

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

This keeps architecture boundaries intact:

- `DialogController` still handles ordering, scoping, and lifecycle.
- Feature modules own their dialog widget composition.
- `DialogHost` remains the single rendering layer entrypoint.

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

### 3. Scope dialogs to a region

```dart
DialogScope(
	controller: controller,
	scopeId: 'details-panel',
	child: DialogHost(
		scopeId: 'details-panel',
		builder: dialogBuilder,
		child: const DetailsPanel(),
	),
)
```

Only requests whose `scopeId` matches `details-panel` render in that host.

## Custom ordering strategy

If you need behavior other than priority-first ordering, provide `orderStrategy`.
Use `orderingData` to attach domain-specific comparison metadata without
overloading `payload`:

```dart
class TicketDialogOrder {
	const TicketDialogOrder(this.rank);

	final int rank;
}

final controller = DialogController(
	orderStrategy: (a, b) {
		final TicketDialogOrder left = a.orderingData! as TicketDialogOrder;
		final TicketDialogOrder right = b.orderingData! as TicketDialogOrder;
		return left.rank.compareTo(right.rank);
	},
);

controller.enqueue(
	DialogRequest(
		id: 'billing-warning',
		orderingData: const TicketDialogOrder(20),
		payload: 'Billing warning',
	),
);

controller.enqueue(
	DialogRequest(
		id: 'security-warning',
		orderingData: const TicketDialogOrder(5),
		payload: 'Security warning',
	),
);
```

In this example, `security-warning` appears before `billing-warning` because
its domain rank is lower.

If your strategy only needs the built-in fields, you can still compare those
directly:

```dart
final controller = DialogController(
	orderStrategy: (a, b) => a.priority.compareTo(b.priority),
);
```