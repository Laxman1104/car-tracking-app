import 'package:car_tracking_app/application/maintenance/maintenance_record_service.dart';
import 'package:car_tracking_app/data/database/app_database.dart';
import 'package:car_tracking_app/data/repositories/attachment_repository.dart';
import 'package:car_tracking_app/data/repositories/fuel_event_repository.dart';
import 'package:car_tracking_app/data/repositories/maintenance_repository.dart';
import 'package:car_tracking_app/data/repositories/service_reminder_repository.dart';
import 'package:car_tracking_app/data/repositories/vehicle_repository.dart';
import 'package:car_tracking_app/presentation/maintenance/maintenance_form_screen.dart';
import 'package:car_tracking_app/presentation/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MaintenanceRepository maintenance;
  late MaintenanceRecordService service;
  late int vehicleId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    maintenance = MaintenanceRepository(database);
    service = MaintenanceRecordService(
      database: database,
      maintenance: maintenance,
      fuelEvents: FuelEventRepository(database),
      attachments: AttachmentRepository(database),
      reminders: ServiceReminderRepository(database),
      fileStore: _FakeFiles(),
    );
    vehicleId = await VehicleRepository(database)
        .create(VehiclesCompanion.insert(displayName: 'Widget Test Car'));
  });

  tearDown(() => database.close());

  Future<void> pump(WidgetTester tester, {MaintenanceSaved? onSaved}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MaintenanceFormScreen(
          vehicleId: vehicleId,
          service: service,
          initialOccurredAt: DateTime.utc(2027, 3, 10),
          onSaved: onSaved,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RM0 maintenance saves normally without a warning', (
    tester,
  ) async {
    int? savedId;
    await pump(tester, onSaved: (id) => savedId = id);
    await tester.enterText(
      find.byKey(const Key('maintenance-odometer')),
      '10240',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-workshop')),
      'Synthetic Centre',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-total-cost')),
      '000',
    );
    expect(find.textContaining('caution', findRichText: true), findsNothing);

    final save = find.byKey(const Key('save-maintenance-record'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(savedId, isNotNull);
    expect((await maintenance.findRecordById(savedId!))!.totalCostSen, 0);
  });

  testWidgets('reminder fields only appear for Service', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('next-service-odometer')), findsOneWidget);
    expect(find.byKey(const Key('next-service-date')), findsOneWidget);

    await tester.tap(find.text('Repairs'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('next-service-odometer')), findsNothing);
    expect(find.byKey(const Key('next-service-date')), findsNothing);

    await tester.tap(find.text('Accessories'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('next-service-odometer')), findsNothing);
  });
}

class _FakeFiles implements AttachmentFileStore {
  @override
  Future<String> absolutePath(String relativePath) async => relativePath;

  @override
  Future<void> deleteFile(String relativePath) async {}

  @override
  Future<void> deleteRecordDirectory(int recordId) async {}

  @override
  Future<String> importFile(
    int recordId,
    MaintenanceAttachmentInput input,
  ) async => '$recordId/${input.fileName}';
}
