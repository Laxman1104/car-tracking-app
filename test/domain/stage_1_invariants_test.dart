import 'dart:math';

import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/odometer/odometer_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('250 deterministic fuel histories preserve every cycle invariant', () {
    final random = Random(1104);
    const engine = FuelCycleEngine();

    for (var sample = 0; sample < 250; sample++) {
      var id = 1;
      var odometer = random.nextInt(10000);
      var openingBrand = _brands[random.nextInt(_brands.length)];
      final events = <FuelEventSnapshot>[
        _fuel(
          id: id++,
          odometerKm: odometer,
          volumeMl: 1 + random.nextInt(60000),
          costSen: random.nextInt(15000),
          full: true,
          brand: openingBrand,
        ),
      ];
      final expected = <_ExpectedCycle>[];
      final cycleCount = 1 + random.nextInt(6);

      for (var cycleIndex = 0; cycleIndex < cycleCount; cycleIndex++) {
        final openingOdometer = odometer;
        var volumeTotal = 0;
        var costTotal = 0;
        var mixed = false;
        final partialCount = random.nextInt(6);

        for (
          var partialIndex = 0;
          partialIndex < partialCount;
          partialIndex++
        ) {
          odometer += random.nextInt(151);
          final brand = _brands[random.nextInt(_brands.length)];
          final volume = 1 + random.nextInt(25000);
          final cost = random.nextInt(7000);
          events.add(
            _fuel(
              id: id++,
              odometerKm: odometer,
              volumeMl: volume,
              costSen: cost,
              full: false,
              brand: brand,
            ),
          );
          volumeTotal += volume;
          costTotal += cost;
          mixed = mixed || brand != openingBrand;
        }

        odometer += random.nextInt(151);
        final closingBrand = _brands[random.nextInt(_brands.length)];
        final closingVolume = 1 + random.nextInt(60000);
        final closingCost = random.nextInt(15000);
        events.add(
          _fuel(
            id: id++,
            odometerKm: odometer,
            volumeMl: closingVolume,
            costSen: closingCost,
            full: true,
            brand: closingBrand,
          ),
        );
        volumeTotal += closingVolume;
        costTotal += closingCost;
        expected.add(
          _ExpectedCycle(
            distanceKm: odometer - openingOdometer,
            volumeMl: volumeTotal,
            costSen: costTotal,
            mixed: mixed,
            attributedBrand: mixed ? null : openingBrand,
          ),
        );
        openingBrand = closingBrand;
      }

      final result = engine.build(events);
      expect(result.completedCycles, hasLength(expected.length));
      expect(result.pendingCycle!.openingFull.id, events.last.id);

      for (var index = 0; index < expected.length; index++) {
        final actual = result.completedCycles[index];
        final wanted = expected[index];
        expect(actual.distanceKm, wanted.distanceKm);
        expect(actual.fuelConsumedMillilitres, wanted.volumeMl);
        expect(actual.fuelCostSen, wanted.costSen);
        expect(actual.attributedBrand, wanted.attributedBrand);
        expect(actual.brandKind == FuelCycleBrandKind.mixed, wanted.mixed);
        if (wanted.distanceKm == 0) {
          expect(actual.fuelEfficiencyKmPerL, isNull);
          expect(actual.costRinggitPerKm, isNull);
        } else {
          expect(
            actual.fuelEfficiencyKmPerL,
            closeTo(wanted.distanceKm * 1000 / wanted.volumeMl, 0.000000001),
          );
          expect(
            actual.costRinggitPerKm,
            closeTo(wanted.costSen / 100 / wanted.distanceKm, 0.000000001),
          );
        }
      }
    }
  });

  test(
    '100 shuffled monotonic timelines always validate and resolve newest',
    () {
      final random = Random(2609);
      const engine = OdometerTimelineEngine();

      for (var sample = 0; sample < 100; sample++) {
        var odometer = random.nextInt(10000);
        final chronological = <OdometerObservation>[];
        for (var index = 0; index < 30; index++) {
          odometer += random.nextInt(51);
          chronological.add(
            OdometerObservation(
              key: OdometerObservationKey(
                index.isEven ? OdometerSource.fuel : OdometerSource.maintenance,
                index + 1,
              ),
              vehicleId: 1,
              occurredAt: DateTime.utc(2027, 1, 1).add(Duration(hours: index)),
              odometerKm: odometer,
            ),
          );
        }

        final shuffled = [...chronological]..shuffle(random);
        final accepted = <OdometerObservation>[];
        for (final candidate in shuffled) {
          expect(
            engine
                .validateInsert(candidate: candidate, existing: accepted)
                .isValid,
            isTrue,
          );
          accepted.add(candidate);
        }

        expect(engine.chronological(shuffled), chronological);
        expect(engine.resolveCurrent(shuffled), chronological.last);
      }
    },
  );
}

const _brands = ['PETRONAS', 'Shell', 'Petron', 'Caltex', 'BHPetrol'];

FuelEventSnapshot _fuel({
  required int id,
  required int odometerKm,
  required int volumeMl,
  required int costSen,
  required bool full,
  required String brand,
}) {
  return FuelEventSnapshot(
    id: id,
    vehicleId: 1,
    occurredAt: DateTime.utc(2027, 1, 1).add(Duration(hours: id)),
    odometerKm: odometerKm,
    fuelBrand: brand,
    fuelVolumeMillilitres: volumeMl,
    costSen: costSen,
    isFullTank: full,
  );
}

class _ExpectedCycle {
  const _ExpectedCycle({
    required this.distanceKm,
    required this.volumeMl,
    required this.costSen,
    required this.mixed,
    required this.attributedBrand,
  });

  final int distanceKm;
  final int volumeMl;
  final int costSen;
  final bool mixed;
  final String? attributedBrand;
}
