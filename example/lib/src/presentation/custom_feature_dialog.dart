import 'package:flutter/material.dart';

class CustomFeatureDialog extends StatelessWidget {
  const CustomFeatureDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 20,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(message),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: onConfirm,
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
