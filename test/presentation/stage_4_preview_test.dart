import 'package:car_tracking_app/dev/stage_4_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first launch collects a vehicle baseline before showing Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const StageFourPreviewApp(useInMemoryDatabase: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Start Tracking'), findsOneWidget);
    expect(find.byKey(const Key('home-screen')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('new-vehicle-name')),
      'My First Car',
    );
    await tester.enterText(
      find.byKey(const Key('new-vehicle-odometer')),
      '12345',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('continue-new-vehicle')));
    await tester.tap(find.byKey(const Key('continue-new-vehicle')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsNothing);
    expect(find.text('My First Car'), findsOneWidget);
    expect(find.textContaining('12,345', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'combined preview exposes maintenance and fuel correction flows',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const StageFourPreviewApp(
          seedPreviewData: true,
          useInMemoryDatabase: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Car Tracker'), findsOneWidget);
      expect(find.text('Proton S70'), findsOneWidget);
      expect(find.textContaining('Stages'), findsNothing);

      await tester.tap(find.byKey(const Key('preview-maintenance')));
      await tester.pumpAndSettle();
      expect(find.text('Maintenance History'), findsOneWidget);
      expect(find.byKey(const Key('active-service-reminder')), findsOneWidget);
      expect(
        find.byKey(const Key('add-service-reminder-to-calendar')),
        findsOneWidget,
      );
      expect(find.textContaining('alerts at'), findsNothing);
      expect(find.textContaining('service interval completed'), findsOneWidget);
      await tester.tap(find.text('General Service'));
      await tester.pumpAndSettle();
      expect(find.text('Record Details'), findsOneWidget);
      expect(find.byKey(const Key('edit-maintenance-record')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('preview-fuel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('completed-cycle-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cycle-event-2')));
      await tester.pumpAndSettle();
      expect(find.text('Fuel Event'), findsOneWidget);
      expect(find.byKey(const Key('edit-fuel-event')), findsOneWidget);
      expect(find.byKey(const Key('delete-fuel-event')), findsOneWidget);
    },
  );

  testWidgets('Home opens analytics with all upcoming service reminders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const StageFourPreviewApp(
        seedPreviewData: true,
        useInMemoryDatabase: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final fuelRect = tester.getRect(find.byKey(const Key('preview-fuel')));
    final maintenanceRect = tester.getRect(
      find.byKey(const Key('preview-maintenance')),
    );
    expect(fuelRect.top, maintenanceRect.top);
    expect(fuelRect.height, maintenanceRect.height);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.text('View analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Fuel Logs + Maintenance'), findsOneWidget);
    expect(find.text('Fuel and maintenance by month'), findsOneWidget);
    expect(find.byKey(const Key('monthly-spending-year')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('analytics-sections')),
        matching: find.text('Maintenance'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Upcoming service reminders'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('General Service'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('General Service'), findsOneWidget);
    expect(find.text('Tyre Rotation'), findsOneWidget);
  });

  testWidgets('maintenance saves and reminder completion refresh immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const StageFourPreviewApp(
        seedPreviewData: true,
        useInMemoryDatabase: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-maintenance')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-service-reminder-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as done').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('General Service'), findsWidgets);

    await tester.tap(find.byKey(const Key('add-maintenance-record-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('maintenance-service-title')),
      'Brake Inspection',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-odometer')),
      '11000',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-workshop')),
      'Test Workshop',
    );
    await tester.enterText(
      find.byKey(const Key('maintenance-total-cost')),
      '4500',
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-maintenance-record')),
    );
    await tester.tap(find.byKey(const Key('save-maintenance-record')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Brake Inspection'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('11,000', findRichText: true), findsOneWidget);
  });

  testWidgets('retirement starts a clean vehicle and archives prior history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const StageFourPreviewApp(
        seedPreviewData: true,
        useInMemoryDatabase: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-vehicle-lifecycle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retire-start-new-vehicle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-vehicle-name')),
      'Samsung Test Car',
    );
    await tester.enterText(
      find.byKey(const Key('new-vehicle-odometer')),
      '2500',
    );
    await tester.tap(find.byKey(const Key('continue-new-vehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-retire-vehicle')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Samsung Test Car'), findsOneWidget);
    expect(find.textContaining('2,500', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-vehicle-lifecycle')));
    await tester.pumpAndSettle();
    expect(find.text('Proton S70'), findsOneWidget);
    await tester.tap(find.text('Proton S70'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuel history'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-fuel-event-fab')), findsNothing);
    expect(find.byKey(const Key('completed-cycle-1')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-past-vehicle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('This cannot be undone.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-past-vehicle')));
    await tester.pumpAndSettle();
    expect(find.text('No past vehicles yet.'), findsOneWidget);
    expect(find.text('Proton S70'), findsNothing);
  });
}
