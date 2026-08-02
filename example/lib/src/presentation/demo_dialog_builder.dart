import 'package:flutter/material.dart';

import 'package:dialog_flow/dialog_flow.dart';

Widget buildDemoDialog(
  BuildContext context,
  DialogRequest request,
  DialogDismissCallback dismiss,
) {
  Widget body = Text('Dialog ${request.id}');

  final Object? payload = request.payload;
  if (payload is String) {
    body = Text(payload, textAlign: TextAlign.center);
  } else if (payload is Map<String, Object?>) {
    body = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          payload['title']! as String,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(payload['body']! as String, textAlign: TextAlign.center),
      ],
    );
  }

  return Material(
    elevation: 18,
    borderRadius: BorderRadius.circular(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            body,
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => dismiss(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    ),
  );
}
