import 'package:car_tracking_app/domain/validation/scaled_decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScaledDecimalParser', () {
    test('converts litres and money without floating-point rounding', () {
      expect(ScaledDecimalParser.parse('32.40', fractionDigits: 3), 32400);
      expect(ScaledDecimalParser.parse('68.00', fractionDigits: 2), 6800);
      expect(ScaledDecimalParser.parse('0', fractionDigits: 2), 0);
      expect(ScaledDecimalParser.parse('0.001', fractionDigits: 3), 1);
    });

    test('rejects malformed, negative, and over-precise values', () {
      expect(ScaledDecimalParser.parse('', fractionDigits: 2), isNull);
      expect(ScaledDecimalParser.parse('-1', fractionDigits: 2), isNull);
      expect(ScaledDecimalParser.parse('1.001', fractionDigits: 2), isNull);
      expect(ScaledDecimalParser.parse('1.2.3', fractionDigits: 2), isNull);
    });
  });
}
