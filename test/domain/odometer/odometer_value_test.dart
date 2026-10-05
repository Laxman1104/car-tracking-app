import 'package:car_tracking_app/domain/odometer/odometer_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts and formats whole-number odometers', () {
    expect(parseOdometerKm('463'), 463.0);
    expect(parseOdometerKm('463.8'), isNull);
    expect(formatOdometerKm(12463), '12,463');
    expect(formatOdometerKm(12463.0), '12,463');
  });
}
