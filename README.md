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
	- [2. Render dialogs through a host](#2-render-dialogs-through-a-host)
	- [2.1 Queue a feature-owned custom widget](#21-queue-a-feature-owned-custom-widget)
	- [2.2 Await dialog outcomes](#22-await-dialog-outcomes)
- [Custom ordering strategy](#custom-ordering-strategy)
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

When a custom strategy returns `0`, the controller still preserves insertion
order for deterministic ties.

If your strategy only needs the built-in fields, you can still compare those
directly:

```dart
final controller = DialogController(
	orderStrategy: (a, b) => a.priority.compareTo(b.priority),
);
```

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
				final DialogRequest? request =
					resolvedController.current();

				return Stack(
					children: [
						child,
						if (request != null)
							Positioned.fill(
								child: ColoredBox(
									color: const Color(0x66000000),
									child: Center(
										child: builder(
											context,
											request,
											([outcome]) => resolvedController.dismissCurrentWithOutcome(
												outcome: outcome,
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
