import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/database/schema.dart';
import 'package:car_tracking_app/data/mappers/history_mappers.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:car_tracking_app/domain/fuel/fuel_cycle.dart';
import 'package:car_tracking_app/domain/fuel/fuel_history_correction.dart';
import 'package:car_tracking_app/domain/maintenance/maintenance.dart';
import 'package:car_tracking_app/domain/odometer/odometer_timeline.dart';
import 'package:car_tracking_app/domain/validation/domain_validation.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fuelEngine = FuelCycleEngine();
  const correctionEngine = FuelHistoryCorrectionEngine();
  const odometerEngine = OdometerTimelineEngine();
  const validator = DomainValidator();
  const maintenanceService = MaintenanceDomainService();

  FuelEventSnapshot fuel({
    required int id,
    required double odometerKm,
    required int volumeMl,
    required int costSen,
    required bool full,
    String brand = 'PETRONAS',
    int vehicleId = 1,
    int? tripMetres,
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
      tripDistanceMetres: tripMetres,
    );
  }

  OdometerObservation observation({
    required OdometerSource source,
    required int id,
    required int day,
    required double odometerKm,
  }) {
    return OdometerObservation(
      key: OdometerObservationKey(source, id),
      vehicleId: 1,
      occurredAt: DateTime.utc(2027, 9, day),
      odometerKm: odometerKm,
    );
  }

  group('Ground Truth fuel and chronology acceptance', () {
    test('A. first Full after unknown dealer fuel is Starting Reference', () {
      final result = fuelEngine.build([
        fuel(
          id: 1,
          odometerKm: 250,
          volumeMl: 40000,
          costSen: 7000,
          full: true,
        ),
      ]);

      expect(result.completedCycles, isEmpty);
      expect(result.pendingCycle!.openingFull.odometerKm, 250);
    });

    test('B. next Full calculates 400 / 28 = 14.29 km/L', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 250,
              volumeMl: 40000,
              costSen: 7000,
              full: true,
            ),
            fuel(
              id: 2,
              odometerKm: 650,
              volumeMl: 28000,
              costSen: 5600,
              full: true,
            ),
          ])
          .completedCycles
          .single;

      expect(cycle.distanceKm, 400);
      expect(cycle.fuelConsumedMillilitres, 28000);
      expect(cycle.fuelEfficiencyKmPerL, closeTo(14.285714, 0.000001));
      expect(cycle.costRinggitPerKm, closeTo(0.14, 0.000001));
    });

    test('C. early top-up Full creates a valid 100 km cycle', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 1000,
              volumeMl: 1000,
              costSen: 200,
              full: true,
            ),
            fuel(
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

    test('D. one partial calculates 450 / 30 = 15 km/L', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 2000,
              volumeMl: 1000,
              costSen: 200,
              full: true,
            ),
            fuel(
              id: 2,
              odometerKm: 2200,
              volumeMl: 12000,
              costSen: 2400,
              full: false,
            ),
            fuel(
              id: 3,
              odometerKm: 2450,
              volumeMl: 18000,
              costSen: 3600,
              full: true,
            ),
          ])
          .completedCycles
          .single;

      expect(cycle.distanceKm, 450);
      expect(cycle.fuelConsumedMillilitres, 30000);
      expect(cycle.fuelEfficiencyKmPerL, 15);
    });

    test('E. any number of Not Full events stays Pending until Full', () {
      final openEvents = [
        fuel(id: 1, odometerKm: 3000, volumeMl: 1000, costSen: 200, full: true),
        fuel(
          id: 2,
          odometerKm: 3100,
          volumeMl: 5000,
          costSen: 1000,
          full: false,
        ),
        fuel(
          id: 3,
          odometerKm: 3200,
          volumeMl: 6000,
          costSen: 1200,
          full: false,
        ),
        fuel(
          id: 4,
          odometerKm: 3300,
          volumeMl: 7000,
          costSen: 1400,
          full: false,
        ),
      ];
      final pending = fuelEngine.build(openEvents);
      expect(pending.completedCycles, isEmpty);
      expect(pending.pendingCycle!.accumulatedFuelMillilitres, 18000);

      final completed = fuelEngine.build([
        ...openEvents,
        fuel(
          id: 5,
          odometerKm: 3400,
          volumeMl: 8000,
          costSen: 1600,
          full: true,
        ),
      ]);
      expect(completed.completedCycles.single.fuelConsumedMillilitres, 26000);
      expect(completed.pendingCycle!.openingFull.id, 5);
    });

    test(
      'F. service advances shared odometer but fuel distance remains 430 km',
      () {
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
        expect(odometerEngine.resolveCurrent(timeline)!.odometerKm, 10430);

        final cycle = fuelEngine
            .build([
              fuel(
                id: 1,
                odometerKm: 10000,
                volumeMl: 1000,
                costSen: 200,
                full: true,
              ),
              fuel(
                id: 3,
                odometerKm: 10430,
                volumeMl: 30000,
                costSen: 6000,
                full: true,
              ),
            ])
            .completedCycles
            .single;
        expect(cycle.distanceKm, 430);
      },
    );

    test(
      'G. Trip B 434 versus odometer 430 returns 4 km and does not block',
      () {
        final validation = validator.validateFuelValues(
          odometerKm: 10430,
          fuelVolumeMillilitres: 30000,
          costSen: 6000,
        );
        final difference = validator.absoluteTripDifferenceMetres(
          odometerDistanceKm: 430,
          tripDistanceMetres: 434000,
        );

        expect(validation.isValid, isTrue);
        expect(difference, 4000);
      },
    );

    test('H. intermediate Shell fuel makes PETRONAS cycle Mixed', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 1000,
              volumeMl: 1000,
              costSen: 200,
              full: true,
            ),
            fuel(
              id: 2,
              odometerKm: 1200,
              volumeMl: 12000,
              costSen: 2400,
              full: false,
              brand: 'Shell',
            ),
            fuel(
              id: 3,
              odometerKm: 1450,
              volumeMl: 18000,
              costSen: 3600,
              full: true,
              brand: 'Petron',
            ),
          ])
          .completedCycles
          .single;

      expect(cycle.brandKind, FuelCycleBrandKind.mixed);
      expect(cycle.attributedBrand, isNull);
    });

    test('I. cycle without partials exposes exactly both Full events', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 1000,
              volumeMl: 1000,
              costSen: 200,
              full: true,
            ),
            fuel(
              id: 2,
              odometerKm: 1100,
              volumeMl: 7000,
              costSen: 1400,
              full: true,
            ),
          ])
          .completedCycles
          .single;

      expect(cycle.events.map((event) => event.id), [1, 2]);
    });

    test('L. correcting historical odometer rebuilds affected cycles', () {
      final events = [
        fuel(id: 1, odometerKm: 1000, volumeMl: 1000, costSen: 200, full: true),
        fuel(
          id: 2,
          odometerKm: 1200,
          volumeMl: 12000,
          costSen: 2400,
          full: true,
        ),
        fuel(
          id: 3,
          odometerKm: 1500,
          volumeMl: 18000,
          costSen: 3600,
          full: true,
        ),
      ];
      final corrected = correctionEngine.editEvent(
        events: events,
        replacement: fuel(
          id: 2,
          odometerKm: 1250,
          volumeMl: 12000,
          costSen: 2400,
          full: true,
        ),
      );

      expect(corrected.completedCycles.map((cycle) => cycle.distanceKm), [
        250,
        250,
      ]);
    });

    test(
      'M. valid backdated 10,120 reading is accepted without becoming current',
      () {
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
        final backdated = observation(
          source: OdometerSource.fuel,
          id: 3,
          day: 11,
          odometerKm: 10120,
        );

        expect(
          validator
              .validateOdometerInsert(candidate: backdated, existing: existing)
              .isValid,
          isTrue,
        );
        expect(
          odometerEngine.resolveCurrent([...existing, backdated])!.odometerKm,
          10250,
        );
      },
    );

    test('N. invalid backdated 10,400 reading is blocked', () {
      final validation = validator.validateOdometerInsert(
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

    test('P. RM0 fuel remains valid and km/L still calculates', () {
      expect(
        validator
            .validateFuelValues(
              odometerKm: 650,
              fuelVolumeMillilitres: 28000,
              costSen: 0,
            )
            .showZeroCostCaution,
        isTrue,
      );
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 250,
              volumeMl: 40000,
              costSen: 7000,
              full: true,
            ),
            fuel(
              id: 2,
              odometerKm: 650,
              volumeMl: 28000,
              costSen: 0,
              full: true,
            ),
          ])
          .completedCycles
          .single;
      expect(cycle.fuelEfficiencyKmPerL, closeTo(14.285714, 0.000001));
      expect(cycle.fuelCostSen, 0);
    });

    test('Q. same-odometer Full events show null km/L and cost/km', () {
      final cycle = fuelEngine
          .build([
            fuel(
              id: 1,
              odometerKm: 5000,
              volumeMl: 1000,
              costSen: 200,
              full: true,
            ),
            fuel(
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

    test('R. editing mistaken Full flag retains event and rebuilds cycles', () {
      final events = [
        fuel(id: 1, odometerKm: 1000, volumeMl: 1000, costSen: 200, full: true),
        fuel(
          id: 2,
          odometerKm: 1200,
          volumeMl: 12000,
          costSen: 2400,
          full: true,
        ),
        fuel(
          id: 3,
          odometerKm: 1500,
          volumeMl: 18000,
          costSen: 3600,
          full: true,
        ),
      ];
      final rebuilt = correctionEngine.editEvent(
        events: events,
        replacement: fuel(
          id: 2,
          odometerKm: 1200,
          volumeMl: 12000,
          costSen: 2400,
          full: false,
        ),
      );

      expect(rebuilt.completedCycles, hasLength(1));
      expect(rebuilt.completedCycles.single.events.map((event) => event.id), [
        1,
        2,
        3,
      ]);
      expect(rebuilt.completedCycles.single.fuelConsumedMillilitres, 30000);
    });

    test(
      'S. deleting duplicate Full merges and recalculates surrounding cycles',
      () {
        final events = [
          fuel(
            id: 1,
            odometerKm: 1000,
            volumeMl: 1000,
            costSen: 200,
            full: true,
          ),
          fuel(
            id: 2,
            odometerKm: 1200,
            volumeMl: 12000,
            costSen: 2400,
            full: true,
          ),
          fuel(
            id: 3,
            odometerKm: 1500,
            volumeMl: 18000,
            costSen: 3600,
            full: true,
          ),
        ];
        final rebuilt = correctionEngine.deleteEvent(
          events: events,
          vehicleId: 1,
          eventId: 2,
        );

        expect(rebuilt.completedCycles, hasLength(1));
        expect(rebuilt.completedCycles.single.distanceKm, 500);
        expect(rebuilt.completedCycles.single.events.map((event) => event.id), [
          1,
          3,
        ]);
        expect(rebuilt.completedCycles.single.fuelConsumedMillilitres, 18000);
      },
    );
  });

  group('Ground Truth maintenance and persistence acceptance', () {
    late AppDatabase database;
    late VehicleRepository vehicles;
    late FuelEventRepository fuelEvents;
    late MaintenanceRepository maintenance;
    late AttachmentRepository attachments;
    late ServiceReminderRepository reminders;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      vehicles = VehicleRepository(database);
      fuelEvents = FuelEventRepository(database);
      maintenance = MaintenanceRepository(database);
      attachments = AttachmentRepository(database);
      reminders = ServiceReminderRepository(database);
    });

    tearDown(() => database.close());

    Future<int> createActiveVehicle(String name) {
      return vehicles.create(VehiclesCompanion.insert(displayName: name));
    }

    Future<int> createServiceRecord(int vehicleId, {int totalCostSen = 0}) {
      return maintenance.createRecord(
        MaintenanceRecordsCompanion.insert(
          vehicleId: vehicleId,
          occurredAt: DateTime.utc(2027, 3, 10),
          odometerKm: 10240,
          category: MaintenanceCategory.service,
          totalCostSen: totalCostSen,
        ),
      );
    }

    test(
      'J. whole-service reminder becomes due by whichever target is reached',
      () async {
        final vehicleId = await createActiveVehicle('Reminder Test Car');
        final recordId = await createServiceRecord(vehicleId);
        final plannedReminder = maintenanceService
            .buildPlan(
              vehicleId: vehicleId,
              maintenanceRecordId: recordId,
              category: MaintenanceCategory.service,
              items: const [],
              nextServiceDate: DateTime.utc(2027, 9, 10),
              nextServiceOdometerKm: 20000,
            )
            .reminder!;
        final reminderId = await reminders.create(
          ServiceRemindersCompanion.insert(
            vehicleId: vehicleId,
            maintenanceRecordId: recordId,
            targetDate: Value(plannedReminder.targetDate),
            targetOdometerKm: Value(plannedReminder.targetOdometerKm),
          ),
        );
        final reminder = (await reminders.findById(reminderId))!.toTarget();

        final dateFirst = maintenanceService.evaluateReminder(
          reminder: reminder,
          now: DateTime.utc(2027, 9, 10),
          currentOdometerKm: 19000,
        );
        final mileageFirst = maintenanceService.evaluateReminder(
          reminder: reminder,
          now: DateTime.utc(2027, 9, 1),
          currentOdometerKm: 20000,
        );
        expect(dateFirst.reachedTriggers, {ServiceReminderTrigger.date});
        expect(mileageFirst.reachedTriggers, {ServiceReminderTrigger.mileage});
      },
    );

    test('K. two images and one PDF remain attached to one record', () async {
      final vehicleId = await createActiveVehicle('Attachment Test Car');
      final recordId = await createServiceRecord(vehicleId);
      for (final fixture in [
        (AttachmentKind.image, 'page-1.jpg', 'image/jpeg'),
        (AttachmentKind.image, 'page-2.jpg', 'image/jpeg'),
        (AttachmentKind.pdf, 'invoice.pdf', 'application/pdf'),
      ]) {
        await attachments.create(
          AttachmentsCompanion.insert(
            vehicleId: vehicleId,
            maintenanceRecordId: recordId,
            kind: fixture.$1,
            originalFileName: fixture.$2,
            relativePath: 'attachments/$recordId/${fixture.$2}',
            mimeType: fixture.$3,
            byteSize: 100,
          ),
        );
      }

      final stored = await attachments.findForRecord(recordId);
      expect(stored, hasLength(3));
      expect(
        stored.where((entry) => entry.kind == AttachmentKind.image),
        hasLength(2),
      );
      expect(
        stored.where((entry) => entry.kind == AttachmentKind.pdf),
        hasLength(1),
      );
      expect(
        stored.every((entry) => entry.maintenanceRecordId == recordId),
        isTrue,
      );
      expect(
        (await maintenance.findRecordById(recordId))!
            .toOdometerObservation()
            .odometerKm,
        10240,
      );
    });

    test('O. RM0 warranty maintenance saves normally', () async {
      final vehicleId = await createActiveVehicle('Warranty Test Car');
      final recordId = await createServiceRecord(vehicleId, totalCostSen: 0);

      expect((await maintenance.findRecordById(recordId))!.totalCostSen, 0);
      expect(
        validator
            .validateMaintenanceValues(odometerKm: 10240, totalCostSen: 0)
            .isValid,
        isTrue,
      );
    });

    test(
      'U. retiring Vehicle 1 starts independent active Vehicle 2 history',
      () async {
        final firstId = await createActiveVehicle('Vehicle 1');
        await fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: firstId,
            occurredAt: DateTime.utc(2027, 1, 1),
            odometerKm: 1000,
            fuelBrand: 'Synthetic',
            fuelVolumeMillilitres: 1000,
            costSen: 200,
            isFullTank: true,
          ),
        );

        final secondId = await vehicles.retireAndCreate(
          activeVehicleId: firstId,
          retiredAt: DateTime.utc(2028, 1, 1),
          newVehicle: VehiclesCompanion.insert(displayName: 'Vehicle 2'),
        );
        await fuelEvents.create(
          FuelEventsCompanion.insert(
            vehicleId: secondId,
            occurredAt: DateTime.utc(2028, 1, 2),
            odometerKm: 50,
            fuelBrand: 'Synthetic',
            fuelVolumeMillilitres: 1000,
            costSen: 200,
            isFullTank: true,
          ),
        );

        final first = (await vehicles.findById(firstId))!;
        final second = (await vehicles.findById(secondId))!;
        expect(first.isActive, isFalse);
        expect(first.retiredAt, isNotNull);
        expect(second.isActive, isTrue);
        expect(await fuelEvents.findForVehicle(firstId), hasLength(1));
        expect(await fuelEvents.findForVehicle(secondId), hasLength(1));
        expect(
          (await fuelEvents.findForVehicle(firstId)).single.odometerKm,
          1000,
        );
        expect(
          (await fuelEvents.findForVehicle(secondId)).single.odometerKm,
          50,
        );
        expect(
          fuelEngine
              .build(
                (await fuelEvents.findForVehicle(firstId))
                    .map((event) => event.toSnapshot()),
              )
              .pendingCycle!
              .openingFull
              .odometerKm,
          1000,
        );
      },
    );
  });

  // Scenario T (backup/restore) belongs to Stage 6 and is not applicable to
  // the Stage 1 domain model. Its required round-trip test remains explicitly
  // scheduled under Task 6.5.
}
