import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = FuelCycleEngine();

  FuelEventSnapshot event({
    required int id,
    required int odometerKm,
    required int volumeMl,
    required int costSen,
    required bool full,
    String brand = 'PETRONAS',
    int vehicleId = 1,
  }) {
    return FuelEventSnapshot(
      id: id,
      vehicleId: vehicleId,
      occurredAt: DateTime.utc(2027, 1, id),
      odometerKm: odometerKm,
      fuelBrand: brand,
      fuelVolumeMillilitres: volumeMl,
      costSen: costSen,
      isFullTank: full,
    );
  }

  test('first Full is only a Starting Reference and opens Pending', () {
    final result = engine.build([
      event(id: 1, odometerKm: 250, volumeMl: 40000, costSen: 7000, full: true),
    ]);

    expect(result.completedCycles, isEmpty);
    expect(result.pendingCycle, isNotNull);
    expect(result.pendingCycle!.openingFull.odometerKm, 250);
    expect(result.pendingCycle!.accumulatedFuelMillilitres, 0);
    expect(result.pendingCycle!.accumulatedCostSen, 0);
  });

  test('normal Full-to-Full cycle matches 400 / 28 = 14.2857 km/L', () {
    final result = engine.build([
      event(id: 1, odometerKm: 250, volumeMl: 40000, costSen: 7000, full: true),
      event(id: 2, odometerKm: 650, volumeMl: 28000, costSen: 5600, full: true),
    ]);
    final cycle = result.completedCycles.single;

    expect(cycle.distanceKm, 400);
    expect(cycle.fuelConsumedMillilitres, 28000);
    expect(cycle.fuelCostSen, 5600);
    expect(cycle.fuelEfficiencyKmPerL, closeTo(14.285714, 0.000001));
    expect(cycle.costRinggitPerKm, closeTo(0.14, 0.000001));
    expect(result.pendingCycle!.openingFull.id, 2);
  });

  test('early Full top-up remains a valid measured cycle', () {
    final cycle = engine
        .build([
          event(
            id: 1,
            odometerKm: 1000,
            volumeMl: 30000,
            costSen: 6000,
            full: true,
          ),
          event(
            id: 2,
            odometerKm: 1100,
            volumeMl: 7000,
            costSen: 1400,
            full: true,
          ),
        ])
        .completedCycles
        .single;

    expect(cycle.distanceKm, 100);
    expect(cycle.fuelEfficiencyKmPerL, closeTo(14.285714, 0.000001));
  });

  test('one Not Full event remains Pending until closing Full', () {
    final pending = engine.build([
      event(
        id: 1,
        odometerKm: 2000,
        volumeMl: 30000,
        costSen: 6000,
        full: true,
      ),
      event(
        id: 2,
        odometerKm: 2200,
        volumeMl: 12000,
        costSen: 2400,
        full: false,
      ),
    ]);

    expect(pending.completedCycles, isEmpty);
    expect(pending.pendingCycle!.events, hasLength(2));
    expect(pending.pendingCycle!.accumulatedFuelMillilitres, 12000);

    final completed = engine
        .build([
          ...pending.pendingCycle!.events,
          event(
            id: 3,
            odometerKm: 2450,
            volumeMl: 18000,
            costSen: 3600,
            full: true,
          ),
        ])
        .completedCycles
        .single;

    expect(completed.distanceKm, 450);
    expect(completed.fuelConsumedMillilitres, 30000);
    expect(completed.fuelCostSen, 6000);
    expect(completed.fuelEfficiencyKmPerL, 15);
  });

  test('unlimited Not Full events all aggregate into the same cycle', () {
    final events = [
      event(
        id: 1,
        odometerKm: 3000,
        volumeMl: 20000,
        costSen: 4000,
        full: true,
      ),
      event(
        id: 2,
        odometerKm: 3100,
        volumeMl: 5000,
        costSen: 1000,
        full: false,
      ),
      event(
        id: 3,
        odometerKm: 3200,
        volumeMl: 6000,
        costSen: 1200,
        full: false,
      ),
      event(
        id: 4,
        odometerKm: 3300,
        volumeMl: 7000,
        costSen: 1400,
        full: false,
      ),
      event(id: 5, odometerKm: 3400, volumeMl: 8000, costSen: 1600, full: true),
    ];
    final cycle = engine.build(events).completedCycles.single;

    expect(cycle.events, hasLength(5));
    expect(cycle.replenishmentEvents.map((entry) => entry.id), [2, 3, 4, 5]);
    expect(cycle.fuelConsumedMillilitres, 26000);
    expect(cycle.fuelCostSen, 5200);
  });

  test('closing Full brand does not make the previous cycle Mixed', () {
    final cycle = engine
        .build([
          event(
            id: 1,
            odometerKm: 100,
            volumeMl: 1000,
            costSen: 200,
            full: true,
          ),
          event(
            id: 2,
            odometerKm: 200,
            volumeMl: 1000,
            costSen: 200,
            full: true,
            brand: 'Shell',
          ),
        ])
        .completedCycles
        .single;

    expect(cycle.brandKind, FuelCycleBrandKind.singleBrand);
    expect(cycle.attributedBrand, 'PETRONAS');
  });

  test('different intermediate brand marks cycle Mixed', () {
    final cycle = engine
        .build([
          event(
            id: 1,
            odometerKm: 100,
            volumeMl: 1000,
            costSen: 200,
            full: true,
          ),
          event(
            id: 2,
            odometerKm: 150,
            volumeMl: 1000,
            costSen: 200,
            full: false,
            brand: 'Shell',
          ),
          event(
            id: 3,
            odometerKm: 200,
            volumeMl: 1000,
            costSen: 200,
            full: true,
            brand: 'Petron',
          ),
        ])
        .completedCycles
        .single;

    expect(cycle.brandKind, FuelCycleBrandKind.mixed);
    expect(cycle.attributedBrand, isNull);
  });

  test('same-odometer Full boundaries return null rate metrics', () {
    final cycle = engine
        .build([
          event(
            id: 1,
            odometerKm: 5000,
            volumeMl: 1000,
            costSen: 200,
            full: true,
          ),
          event(
            id: 2,
            odometerKm: 5000,
            volumeMl: 1000,
            costSen: 200,
            full: true,
          ),
        ])
        .completedCycles
        .single;

    expect(cycle.distanceKm, 0);
    expect(cycle.fuelEfficiencyKmPerL, isNull);
    expect(cycle.costRinggitPerKm, isNull);
  });

  test('events before first Full remain uncalculated history', () {
    final result = engine.build([
      event(id: 1, odometerKm: 100, volumeMl: 1000, costSen: 200, full: false),
      event(id: 2, odometerKm: 200, volumeMl: 1000, costSen: 200, full: true),
    ]);

    expect(result.preReferenceEvents.single.id, 1);
    expect(result.completedCycles, isEmpty);
    expect(result.pendingCycle!.openingFull.id, 2);
  });

  test('sorts by occurrence and never combines different vehicles', () {
    final later = event(
      id: 2,
      odometerKm: 200,
      volumeMl: 1000,
      costSen: 200,
      full: true,
    );
    final earlier = event(
      id: 1,
      odometerKm: 100,
      volumeMl: 1000,
      costSen: 200,
      full: true,
    );

    expect(
      engine.build([later, earlier]).completedCycles.single.distanceKm,
      100,
    );
    expect(
      () => engine.build([
        earlier,
        event(
          id: 2,
          vehicleId: 2,
          odometerKm: 200,
          volumeMl: 1000,
          costSen: 200,
          full: true,
        ),
      ]),
      throwsA(isA<FuelCycleException>()),
    );
  });

  test('rejects a negative Full-to-Full distance', () {
    expect(
      () => engine.build([
        event(id: 1, odometerKm: 200, volumeMl: 1000, costSen: 200, full: true),
        event(id: 2, odometerKm: 100, volumeMl: 1000, costSen: 200, full: true),
      ]),
      throwsA(isA<FuelCycleException>()),
    );
  });
}
