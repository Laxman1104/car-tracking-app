import 'package:car_tracking_app/dev/fuel_stage_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stage 2 preview opens history, details, and the fuel form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FuelStagePreviewApp());
    await tester.pumpAndSettle();
    expect(find.text('Fuel History'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('completed-cycle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Cycle Details'), findsOneWidget);
    expect(find.text('Not Full · Partial'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-fuel-event-fab')));
    await tester.pumpAndSettle();
    expect(find.text('New Fuel Event'), findsOneWidget);
    expect(find.byKey(const Key('fuel-odometer-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('fuel-odometer-field')),
      '10600',
    );
    await tester.tap(find.byKey(const Key('fuel-brand-shell')));
    await tester.enterText(find.byKey(const Key('fuel-litres-field')), '1200');
    await tester.enterText(find.byKey(const Key('fuel-cost-field')), '2400');
    await tester.tap(find.text('No'));
    final save = find.byKey(const Key('save-fuel-event-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Fuel History'), findsOneWidget);
    expect(find.text('12.00 L · RM24.00 pending'), findsOneWidget);
  });
}
