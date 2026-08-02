import 'package:flutter/material.dart';

class PriorityControlDialog extends StatelessWidget {
  const PriorityControlDialog({
    super.key,
    required this.onQueueHigher,
    required this.onQueueLower,
    required this.onClose,
  });

  final VoidCallback onQueueHigher;
  final VoidCallback onQueueLower;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 20,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Priority Test Dialog',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Use the buttons below to enqueue a higher or lower priority dialog from inside this alert. This dialog stays open so you can queue multiple requests before closing.',
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: onQueueHigher,
                    child: const Text('Queue higher (+30)'),
                  ),
                  OutlinedButton(
                    onPressed: onQueueLower,
                    child: const Text('Queue lower (0)'),
                  ),
                  TextButton(
                    onPressed: onClose,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
