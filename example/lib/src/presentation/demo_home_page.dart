import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dialog_controller/dialog_controller.dart';

import '../framework/bloc_dialog_cubit.dart';
import '../framework/dialog_controller_provider.dart';
import 'custom_feature_dialog.dart';
import 'demo_dialog_builder.dart';
import 'priority_control_dialog.dart';

enum DemoDialogAction { confirmed, cancelled }

class DemoHomePage extends ConsumerStatefulWidget {
  const DemoHomePage({super.key});

  @override
  ConsumerState<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends ConsumerState<DemoHomePage> {
  late final DialogController _coreController;
  late final DialogController _blocController;
  int _requestNonce = 0;

  String _nextRequestId(String prefix) => '$prefix-${++_requestNonce}';

  @override
  void initState() {
    super.initState();
    _coreController = DialogController();
    _blocController = DialogController();
  }

  @override
  void dispose() {
    _coreController.dispose();
    _blocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DialogController riverpodController = ref.watch(
      dialogControllerProvider,
    );

    return BlocListener<BlocDialogCubit, BlocDialogSignal?>(
      listener: (BuildContext context, BlocDialogSignal? signal) {
        if (signal == null) {
          return;
        }

        if (signal.type == BlocDialogSignalType.priorityControl) {
          _blocController.enqueue(
            DialogRequest(
              id: 'bloc-priority-control-${signal.nonce}',
              priority: signal.priority,
              widgetBuilder:
                  (
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

        _blocController.enqueue(
          DialogRequest(
            id: 'bloc-${signal.nonce}',
            priority: signal.priority,
            payload: signal.message,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(title: const Text('Flutter Dialog Demo')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'Each section below owns its own controller and overlay. Dialogs stay inside the section where they were queued.',
            ),
            const SizedBox(height: 24),
            DialogScope(
              controller: _coreController,
              child: DialogHost(
                controller: _coreController,
                builder: buildDemoDialog,
                barrierColor: const Color(0x66000000),
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 360),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Core API (Local Overlay)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This section uses its own controller and renders dialogs only within this card.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              FilledButton(
                                onPressed: () => _coreController.enqueue(
                                  DialogRequest(
                                    id: _nextRequestId('info'),
                                    priority: 1,
                                    payload:
                                        'This is a low-priority dialog in the Core API section.',
                                  ),
                                ),
                                child: const Text('Queue info'),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  final DialogRequestHandle
                                  handle = _coreController.enqueue(
                                    DialogRequest(
                                      id: _nextRequestId('handle-demo'),
                                      priority: 6,
                                      payload:
                                          'This request was enqueued with a handle. Tap Dismiss in the snackbar to close this exact request.',
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Handle-based request queued.',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Dismiss',
                                        onPressed: () {
                                          _coreController.dismiss(handle);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Queue with handle'),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  final DialogRequest request = DialogRequest(
                                    id: _nextRequestId('replaceable'),
                                    priority: 6,
                                    payload:
                                        'This dialog can be updated using its original handle.',
                                  );
                                  final DialogRequestHandle handle =
                                      _coreController.enqueue(request);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Replaceable dialog queued.',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Update',
                                        onPressed: () {
                                          _coreController.replace(
                                            handle,
                                            request.copyWith(
                                              payload:
                                                  'Updated dialog, same queued entry and handle.',
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Queue replaceable dialog'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _coreController.enqueue(
                                  DialogRequest(
                                    id: _nextRequestId('alert'),
                                    priority: 20,
                                    widgetBuilder:
                                        (
                                          BuildContext context,
                                          DialogRequest request,
                                          DialogDismissCallback dismiss,
                                        ) {
                                          return PriorityControlDialog(
                                            onQueueHigher: () {
                                              _coreController.enqueue(
                                                DialogRequest(
                                                  id: _nextRequestId(
                                                    'alert-higher',
                                                  ),
                                                  priority: 30,
                                                  payload:
                                                      'Queued from alert: this higher-priority dialog should appear immediately next.',
                                                ),
                                              );
                                            },
                                            onQueueLower: () {
                                              _coreController.enqueue(
                                                DialogRequest(
                                                  id: _nextRequestId(
                                                    'alert-lower',
                                                  ),
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
                              TextButton(
                                onPressed: () =>
                                    _coreController.dismissCurrent(),
                                child: const Text('Dismiss current dialog'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  final DialogOutcomeHandle<DemoDialogAction>
                                  pending = _coreController
                                      .enqueueForOutcomeWithHandle<
                                        DemoDialogAction
                                      >(
                                        DialogRequest(
                                          id: _nextRequestId('custom-widget'),
                                          priority: 15,
                                          widgetBuilder:
                                              (
                                                BuildContext context,
                                                DialogRequest request,
                                                DialogDismissCallback dismiss,
                                              ) {
                                                return CustomFeatureDialog(
                                                  title: 'Custom Widget Dialog',
                                                  message:
                                                      'This dialog is a feature-owned widget while still using the same queue controller.',
                                                  onConfirm: () => dismiss(
                                                    const DialogOutcome<
                                                      Object?
                                                    >.confirmed(
                                                      DemoDialogAction
                                                          .confirmed,
                                                    ),
                                                  ),
                                                  onCancel: () => dismiss(
                                                    const DialogOutcome<
                                                      Object?
                                                    >.cancelled(
                                                      DemoDialogAction
                                                          .cancelled,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                      );

                                  final DialogOutcome<DemoDialogAction>
                                  outcome = await pending.outcome;

                                  if (!context.mounted) {
                                    return;
                                  }

                                  final String message = switch (outcome.type) {
                                    DialogOutcomeType.confirmed =>
                                      'Dialog outcome: confirmed (${outcome.value})',
                                    DialogOutcomeType.cancelled =>
                                      'Dialog outcome: cancelled (${outcome.value})',
                                    DialogOutcomeType.dismissed =>
                                      'Dialog outcome: dismissed',
                                  };

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      action: SnackBarAction(
                                        label: 'Dismiss Again',
                                        onPressed: () {
                                          _coreController.dismiss(
                                            pending.handle,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Queue custom widget dialog'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            DialogScope(
              controller: _blocController,
              child: DialogHost(
                controller: _blocController,
                builder: buildDemoDialog,
                barrierColor: const Color(0x66000000),
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 280),
                  child: Card(
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
                            'This section maps Cubit signals to its own dialog controller, so dialogs stay inside this card.',
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
                                  context
                                      .read<BlocDialogCubit>()
                                      .queueHighPriority();
                                },
                                child: const Text('BLoC queue high dialog'),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  context
                                      .read<BlocDialogCubit>()
                                      .queueLowPriority();
                                },
                                child: const Text('BLoC queue low dialog'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DialogScope(
              controller: riverpodController,
              child: DialogHost(
                controller: riverpodController,
                builder: buildDemoDialog,
                barrierColor: const Color(0x66000000),
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 280),
                  child: Card(
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
                            'This section binds a Riverpod-provided DialogController to a local host, so dialogs are constrained to this card.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              FilledButton(
                                onPressed: () {
                                  riverpodController.enqueue(
                                    DialogRequest(
                                      id: _nextRequestId(
                                        'riverpod-priority-control',
                                      ),
                                      priority: 18,
                                      widgetBuilder:
                                          (
                                            BuildContext context,
                                            DialogRequest request,
                                            DialogDismissCallback dismiss,
                                          ) {
                                            return PriorityControlDialog(
                                              onQueueHigher: () {
                                                riverpodController.enqueue(
                                                  DialogRequest(
                                                    id: _nextRequestId(
                                                      'riverpod-priority-high',
                                                    ),
                                                    priority: 35,
                                                    payload:
                                                        'Riverpod integration: queued higher-priority follow-up dialog from inside Riverpod priority dialog.',
                                                  ),
                                                );
                                              },
                                              onQueueLower: () {
                                                riverpodController.enqueue(
                                                  DialogRequest(
                                                    id: _nextRequestId(
                                                      'riverpod-priority-low',
                                                    ),
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
                                child: const Text(
                                  'Riverpod open priority dialog',
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: () {
                                  riverpodController.enqueue(
                                    DialogRequest(
                                      id: _nextRequestId(
                                        'riverpod-direct-high',
                                      ),
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
                                  riverpodController.enqueue(
                                    DialogRequest(
                                      id: _nextRequestId('riverpod-direct-low'),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
