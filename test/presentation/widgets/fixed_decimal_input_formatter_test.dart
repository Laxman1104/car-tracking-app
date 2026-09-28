import 'package:car_tracking_app/presentation/widgets/fixed_decimal_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enters digits from the least-significant decimal position', () {
    const formatter = FixedDecimalInputFormatter();
    var value = const TextEditingValue(text: '0.00');

    for (final expected in ['0.03', '0.34', '3.45', '34.59']) {
      final digit = switch (expected) {
        '0.03' => '3',
        '0.34' => '4',
        '3.45' => '5',
        _ => '9',
      };
      value = formatter.formatEditUpdate(
        value,
        TextEditingValue(text: '${value.text}$digit'),
      );
      expect(value.text, expected);
      expect(value.selection.baseOffset, expected.length);
    }
  });

  test('backspace shifts the displayed value toward zero', () {
    const formatter = FixedDecimalInputFormatter();
    const oldValue = TextEditingValue(text: '34.59');
    final value = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: '34.5'),
    );
    expect(value.text, '3.45');
  });
}
