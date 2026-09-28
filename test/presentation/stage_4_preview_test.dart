import 'package:car_tracking_app/dev/stage_4_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'combined preview exposes maintenance and fuel correction flows',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StageFourPreviewApp());
      await tester.pumpAndSettle();
      expect(find.text('Stages 3 & 4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('preview-maintenance')));
      await tester.pumpAndSettle();
      expect(find.text('Maintenance History'), findsOneWidget);
      expect(find.byKey(const Key('active-service-reminder')), findsOneWidget);
      await tester.tap(find.text('Engine oil'));
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
}
