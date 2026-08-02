import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dialog/flutter_dialog.dart';

void main() {
  test('confirmed outcome reports type helpers correctly', () {
    const DialogOutcome<int> outcome = DialogOutcome<int>.confirmed(42);

    expect(outcome.type, DialogOutcomeType.confirmed);
    expect(outcome.isConfirmed, isTrue);
    expect(outcome.isCancelled, isFalse);
    expect(outcome.isDismissed, isFalse);
    expect(outcome.value, 42);
  });

  test('cancelled and dismissed outcomes report their states', () {
    const DialogOutcome<String> cancelled =
        DialogOutcome<String>.cancelled('stop');
    const DialogOutcome<String> dismissed = DialogOutcome<String>.dismissed();

    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.isConfirmed, isFalse);
    expect(cancelled.isDismissed, isFalse);

    expect(dismissed.isDismissed, isTrue);
    expect(dismissed.isConfirmed, isFalse);
    expect(dismissed.isCancelled, isFalse);
    expect(dismissed.value, isNull);
  });

  test('cast preserves type and converts payload type', () {
    const DialogOutcome<Object?> raw = DialogOutcome<Object?>.confirmed('value');

    final DialogOutcome<String> casted = raw.cast<String>();

    expect(casted.type, DialogOutcomeType.confirmed);
    expect(casted.value, 'value');
    expect(casted.isConfirmed, isTrue);
  });
}
