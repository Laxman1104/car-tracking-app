import 'package:car_tracking_app/dev/stage_4_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Car Tracker starts with vehicle setup when no vehicle exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StageFourPreviewApp(useInMemoryDatabase: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Start Tracking'), findsOneWidget);
  });
}
