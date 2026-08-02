import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dialog_controller/dialog_controller.dart';

import '../framework/bloc_dialog_cubit.dart';
import '../framework/dialog_controller_provider.dart';
import 'custom_feature_dialog.dart';
import 'demo_dialog_builder.dart';
import 'priority_control_dialog.dart';

enum DemoDialogAction {
  confirmed,
  cancelled,
}

class DemoHomePage extends ConsumerWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DialogController controller = ref.watch(dialogControllerProvider);

    return BlocListener<BlocDialogCubit, BlocDialogSignal?>(
      listener: (BuildContext context, BlocDialogSignal? signal) {
        if (signal == null) {
          return;
        }

        if (signal.type == BlocDialogSignalType.priorityControl) {
          controller.enqueue(
            DialogRequest(
              id: 'bloc-priority-control-${signal.nonce}',
              priority: signal.priority,
              widgetBuilder: (
                BuildContext context,
                DialogRequest request,
                DialogDismissCallback dismiss,
              ) {
                return PriorityControlDialog(
                  onQueueHigher: () {
                    context.read<BlocDialogCubit>().queueHighPriority();
                  },
                  onQueueLower: () {
                    context.read<BlocDialogCubit>().queueLowPriority();
                  },
                  onClose: () => dismiss(),
                );
              },
            ),
          );
          return;
        }

        controller.enqueue(
          DialogRequest(
            id: 'bloc-${signal.nonce}',
            priority: signal.priority,
            payload: signal.message,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Flutter Dialog Demo'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'The buttons below enqueue dialogs with different priorities and scopes.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton(
                  onPressed: () => controller.enqueue(
                    const DialogRequest(
                      id: 'info',
                      priority: 1,
                      payload: 'This is a low-priority global dialog.',
                    ),
                  ),
                  child: const Text('Queue info'),
                ),
                FilledButton.tonal(
                  onPressed: () => controller.enqueue(
                    DialogRequest(
                      id: 'alert',
                      priority: 20,
                      widgetBuilder: (
                        BuildContext context,
                        DialogRequest request,
                        DialogDismissCallback dismiss,
                      ) {
                        return PriorityControlDialog(
                          onQueueHigher: () {
                            controller.enqueue(
                              const DialogRequest(
                                id: 'alert-higher',
                                priority: 30,
                                payload:
                                    'Queued from alert: this higher-priority dialog should appear immediately next.',
                              ),
                            );
                          },
                          onQueueLower: () {
                            controller.enqueue(
                              const DialogRequest(
                                id: 'alert-lower',
                                priority: 0,
                                payload:
                                    'Queued from alert: this lower-priority dialog should only show after higher-priority dialogs are done.',
                              ),
                            );
                          },
                          onClose: () => dismiss(),
                        );
                      },
                    ),
                  ),
                  child: const Text('Queue alert'),
                ),
                OutlinedButton(
                  onPressed: () => controller.enqueue(
                    const DialogRequest(
                      id: 'details',
                      priority: 10,
                      scopeId: 'details',
                      payload: 'This dialog is scoped to the details card.',
                    ),
                  ),
                  child: const Text('Queue scoped dialog'),
                ),
                TextButton(
                  onPressed: () => controller.dismissCurrent(),
                  child: const Text('Dismiss current global dialog'),
                ),
                FilledButton(
                  onPressed: () async {
                    final DialogOutcome<DemoDialogAction> outcome = await controller
                        .enqueueForOutcome<DemoDialogAction>(
                          DialogRequest(
                            id: 'custom-widget',
                            priority: 15,
                            widgetBuilder: (
                              BuildContext context,
                              DialogRequest request,
                              DialogDismissCallback dismiss,
                            ) {
                              return CustomFeatureDialog(
                                title: 'Custom Widget Dialog',
                                message:
                                    'This dialog is a feature-owned widget while still using the same queue controller.',
                                onConfirm: () => dismiss(
                                  const DialogOutcome<Object?>.confirmed(
                                    DemoDialogAction.confirmed,
                                  ),
                                ),
                                onCancel: () => dismiss(
                                  const DialogOutcome<Object?>.cancelled(
                                    DemoDialogAction.cancelled,
                                  ),
                                ),
                              );
                            },
                          ),
                        );

                    if (!context.mounted) {
                      return;
                    }

                    final String message = switch (outcome.type) {
                      DialogOutcomeType.confirmed =>
                        'Dialog outcome: confirmed (${outcome.value})',
                      DialogOutcomeType.cancelled =>
                        'Dialog outcome: cancelled (${outcome.value})',
                      DialogOutcomeType.dismissed => 'Dialog outcome: dismissed',
                    };

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  child: const Text('Queue custom widget dialog'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Flutter BLoC Integration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These buttons emit BLoC states. BlocListener maps those states to DialogRequest entries, including an interactive priority-control dialog.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.tonal(
                          onPressed: () {
                            context
                                .read<BlocDialogCubit>()
                                .openPriorityControlDialog();
                          },
                          child: const Text('BLoC open priority dialog'),
                        ),
                        FilledButton(
                          onPressed: () {
                            context.read<BlocDialogCubit>().queueHighPriority();
                          },
                          child: const Text('BLoC queue high dialog'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            context.read<BlocDialogCubit>().queueLowPriority();
                          },
                          child: const Text('BLoC queue low dialog'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Riverpod Integration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These buttons read the Riverpod-provided DialogController and can open an interactive priority-control dialog.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          onPressed: () {
                            ref.read(dialogControllerProvider).enqueue(
                              DialogRequest(
                                id: 'riverpod-priority-control',
                                priority: 18,
                                widgetBuilder: (
                                  BuildContext context,
                                  DialogRequest request,
                                  DialogDismissCallback dismiss,
                                ) {
                                  return PriorityControlDialog(
                                    onQueueHigher: () {
                                      ref.read(dialogControllerProvider).enqueue(
                                        const DialogRequest(
                                          id: 'riverpod-priority-high',
                                          priority: 35,
                                          payload:
                                              'Riverpod integration: queued higher-priority follow-up dialog from inside Riverpod priority dialog.',
                                        ),
                                      );
                                    },
                                    onQueueLower: () {
                                      ref.read(dialogControllerProvider).enqueue(
                                        const DialogRequest(
                                          id: 'riverpod-priority-low',
                                          priority: 1,
                                          payload:
                                              'Riverpod integration: queued lower-priority follow-up dialog from inside Riverpod priority dialog.',
                                        ),
                                      );
                                    },
                                    onClose: () => dismiss(),
                                  );
                                },
                              ),
                            );
                          },
                          child: const Text('Riverpod open priority dialog'),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(dialogControllerProvider).enqueue(
                              const DialogRequest(
                                id: 'riverpod-direct-high',
                                priority: 35,
                                payload:
                                    'Riverpod integration: queued high-priority dialog directly through DialogController provider.',
                              ),
                            );
                          },
                          child: const Text('Riverpod queue high dialog'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(dialogControllerProvider).enqueue(
                              const DialogRequest(
                                id: 'riverpod-direct-low',
                                priority: 1,
                                payload:
                                    'Riverpod integration: queued low-priority dialog directly through DialogController provider.',
                              ),
                            );
                          },
                          child: const Text('Riverpod queue low dialog'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DialogScope(
                  controller: controller,
                  scopeId: 'details',
                  child: DialogHost(
                    controller: controller,
                    scopeId: 'details',
                    builder: buildDemoDialog,
                    barrierColor: const Color(0x66000000),
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Scoped region',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This card uses the same controller but isolates its dialogs by scope.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => controller.enqueue(
                              const DialogRequest(
                                id: 'details-1',
                                priority: 5,
                                scopeId: 'details',
                                payload: 'Scoped dialogs render inside this card.',
                              ),
                            ),
                            child: const Text('Show scoped dialog'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
