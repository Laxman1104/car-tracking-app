import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/odometer/odometer_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = OdometerTimelineEngine();

  OdometerObservation observation({
    required OdometerSource source,
    required int id,
    required int day,
    required int odometerKm,
    int vehicleId = 1,
  }) {
    return OdometerObservation(
      key: OdometerObservationKey(source, id),
      vehicleId: vehicleId,
      occurredAt: DateTime.utc(2027, 9, day),
      odometerKm: odometerKm,
    );
  }

  test('newest occurrence across Fuel and Maintenance is current', () {
    final current = engine.resolveCurrent([
      observation(
        source: OdometerSource.fuel,
        id: 10,
        day: 10,
        odometerKm: 10000,
      ),
      observation(
        source: OdometerSource.maintenance,
        id: 20,
        day: 11,
        odometerKm: 10250,
      ),
      observation(
        source: OdometerSource.fuel,
        id: 1,
        day: 12,
        odometerKm: 10430,
      ),
    ]);

    expect(current!.key, const OdometerObservationKey(OdometerSource.fuel, 1));
    expect(current.odometerKm, 10430);
  });

  test('valid backdated reading fits between both chronological neighbors', () {
    final existing = [
      observation(
        source: OdometerSource.fuel,
        id: 1,
        day: 10,
        odometerKm: 10000,
      ),
      observation(
        source: OdometerSource.maintenance,
        id: 2,
        day: 12,
        odometerKm: 10250,
      ),
    ];
    final candidate = observation(
      source: OdometerSource.fuel,
      id: 3,
      day: 11,
      odometerKm: 10120,
    );

    final validation = engine.validateInsert(
      candidate: candidate,
      existing: existing,
    );
    expect(validation.isValid, isTrue);
    expect(validation.previous!.odometerKm, 10000);
    expect(validation.next!.odometerKm, 10250);
    expect(engine.resolveCurrent([...existing, candidate])!.odometerKm, 10250);
  });

  test('backdated reading above its next neighbor is rejected', () {
    final validation = engine.validateInsert(
      candidate: observation(
        source: OdometerSource.fuel,
        id: 3,
        day: 11,
        odometerKm: 10400,
      ),
      existing: [
        observation(
          source: OdometerSource.fuel,
          id: 1,
          day: 10,
          odometerKm: 10000,
        ),
        observation(
          source: OdometerSource.maintenance,
          id: 2,
          day: 12,
          odometerKm: 10250,
        ),
      ],
    );

    expect(validation.isValid, isFalse);
    expect(
      validation.issues,
      contains(OdometerValidationIssue.aboveNextReading),
    );
  });

  test('forward reading below the previous reading is rejected', () {
    final validation = engine.validateInsert(
      candidate: observation(
        source: OdometerSource.fuel,
        id: 2,
        day: 12,
        odometerKm: 9999,
      ),
      existing: [
        observation(
          source: OdometerSource.maintenance,
          id: 1,
          day: 11,
          odometerKm: 10000,
        ),
      ],
    );

    expect(validation.isValid, isFalse);
    expect(
      validation.issues,
      contains(OdometerValidationIssue.belowPreviousReading),
    );
  });

  test('equal odometer readings are valid chronological neighbors', () {
    final validation = engine.validateInsert(
      candidate: observation(
        source: OdometerSource.fuel,
        id: 2,
        day: 12,
        odometerKm: 5000,
      ),
      existing: [
        observation(
          source: OdometerSource.fuel,
          id: 1,
          day: 11,
          odometerKm: 5000,
        ),
      ],
    );

    expect(validation.isValid, isTrue);
  });

  test(
    'historical edit validates against neighbors without comparing itself',
    () {
      final original = observation(
        source: OdometerSource.fuel,
        id: 2,
        day: 11,
        odometerKm: 10100,
      );
      final existing = [
        observation(
          source: OdometerSource.fuel,
          id: 1,
          day: 10,
          odometerKm: 10000,
        ),
        original,
        observation(
          source: OdometerSource.maintenance,
          id: 3,
          day: 12,
          odometerKm: 10200,
        ),
      ];

      expect(
        engine
            .validateEdit(
              candidate: observation(
                source: OdometerSource.fuel,
                id: 2,
                day: 11,
                odometerKm: 10150,
              ),
              existing: existing,
            )
            .isValid,
        isTrue,
      );
      expect(
        engine
            .validateEdit(
              candidate: observation(
                source: OdometerSource.fuel,
                id: 2,
                day: 11,
                odometerKm: 10300,
              ),
              existing: existing,
            )
            .issues,
        contains(OdometerValidationIssue.aboveNextReading),
      );
    },
  );

  test('maintenance between Full events never becomes a fuel boundary', () {
    final timeline = [
      observation(
        source: OdometerSource.fuel,
        id: 1,
        day: 10,
        odometerKm: 10000,
      ),
      observation(
        source: OdometerSource.maintenance,
        id: 2,
        day: 11,
        odometerKm: 10250,
      ),
      observation(
        source: OdometerSource.fuel,
        id: 3,
        day: 12,
        odometerKm: 10430,
      ),
    ];
    expect(engine.resolveCurrent(timeline)!.odometerKm, 10430);

    final fuelCycle = const FuelCycleEngine()
        .build([
          FuelEventSnapshot(
            id: 1,
            vehicleId: 1,
            occurredAt: DateTime.utc(2027, 9, 10),
            odometerKm: 10000,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 1000,
            costSen: 200,
            isFullTank: true,
          ),
          FuelEventSnapshot(
            id: 3,
            vehicleId: 1,
            occurredAt: DateTime.utc(2027, 9, 12),
            odometerKm: 10430,
            fuelBrand: 'PETRONAS',
            fuelVolumeMillilitres: 30000,
            costSen: 6000,
            isFullTank: true,
          ),
        ])
        .completedCycles
        .single;

    expect(fuelCycle.distanceKm, 430);
  });

  test('mixed vehicle observations cannot form one timeline', () {
    expect(
      () => engine.resolveCurrent([
        observation(
          source: OdometerSource.fuel,
          id: 1,
          day: 10,
          odometerKm: 100,
          vehicleId: 1,
        ),
        observation(
          source: OdometerSource.fuel,
          id: 2,
          day: 11,
          odometerKm: 200,
          vehicleId: 2,
        ),
      ]),
      throwsA(isA<OdometerTimelineException>()),
    );
  });
}
