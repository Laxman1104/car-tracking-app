import 'package:car_tracking_app/domain/odometer/odometer_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and formats odometers to one decimal place', () {
    expect(parseOdometerKm('463.8'), 463.8);
    expect(parseOdometerKm('463.89'), isNull);
    expect(formatOdometerKm(12463.8), '12,463.8');
    expect(formatOdometerKm(12463), '12,463.0');
  });
}
