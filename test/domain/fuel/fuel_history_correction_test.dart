import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/fuel/fuel_history_correction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = FuelHistoryCorrectionEngine();

  FuelEventSnapshot event({
    required int id,
    required int odometerKm,
    required int volumeMl,
    required bool full,
  }) {
    return FuelEventSnapshot(
      id: id,
      vehicleId: 1,
      occurredAt: DateTime.utc(2027, 1, id),
      odometerKm: odometerKm,
      fuelBrand: 'PETRONAS',
      fuelVolumeMillilitres: volumeMl,
      costSen: volumeMl ~/ 5,
      isFullTank: full,
    );
  }

  test('editing a Full boundary to Not Full rebuilds surrounding cycles', () {
    final original = [
      event(id: 1, odometerKm: 1000, volumeMl: 10000, full: true),
      event(id: 2, odometerKm: 1200, volumeMl: 12000, full: true),
      event(id: 3, odometerKm: 1500, volumeMl: 18000, full: true),
    ];
    expect(engine.rebuild(original).completedCycles, hasLength(2));

    final rebuilt = engine.editEvent(
      events: original,
      replacement: event(id: 2, odometerKm: 1200, volumeMl: 12000, full: false),
    );

    expect(rebuilt.completedCycles, hasLength(1));
    expect(rebuilt.completedCycles.single.distanceKm, 500);
    expect(rebuilt.completedCycles.single.fuelConsumedMillilitres, 30000);
    expect(rebuilt.completedCycles.single.events.map((entry) => entry.id), [
      1,
      2,
      3,
    ]);
  });

  test(
    'editing historical boundary odometer recalculates both adjacent cycles',
    () {
      final original = [
        event(id: 1, odometerKm: 1000, volumeMl: 10000, full: true),
        event(id: 2, odometerKm: 1200, volumeMl: 12000, full: true),
        event(id: 3, odometerKm: 1500, volumeMl: 18000, full: true),
      ];

      final rebuilt = engine.editEvent(
        events: original,
        replacement: event(
          id: 2,
          odometerKm: 1250,
          volumeMl: 12000,
          full: true,
        ),
      );

      expect(rebuilt.completedCycles.map((cycle) => cycle.distanceKm), [
        250,
        250,
      ]);
    },
  );

  test('editing partial litres and cost recalculates its containing cycle', () {
    final original = [
      event(id: 1, odometerKm: 1000, volumeMl: 10000, full: true),
      event(id: 2, odometerKm: 1100, volumeMl: 5000, full: false),
      event(id: 3, odometerKm: 1200, volumeMl: 7000, full: true),
    ];

    final rebuilt = engine.editEvent(
      events: original,
      replacement: event(id: 2, odometerKm: 1100, volumeMl: 6000, full: false),
    );

    expect(rebuilt.completedCycles.single.fuelConsumedMillilitres, 13000);
    expect(rebuilt.completedCycles.single.fuelCostSen, 2600);
  });

  test('editing an unknown or ambiguous identity is rejected', () {
    final original = [
      event(id: 1, odometerKm: 1000, volumeMl: 10000, full: true),
    ];
    expect(
      () => engine.editEvent(
        events: original,
        replacement: event(
          id: 2,
          odometerKm: 1100,
          volumeMl: 5000,
          full: false,
        ),
      ),
      throwsA(isA<FuelHistoryCorrectionException>()),
    );
    expect(
      () => engine.editEvent(
        events: [...original, ...original],
        replacement: original.single,
      ),
      throwsA(isA<FuelHistoryCorrectionException>()),
    );
  });
}
