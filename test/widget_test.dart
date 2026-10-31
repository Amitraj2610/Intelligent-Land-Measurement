import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_land_measurement/main.dart';

void main() {
  testWidgets('Intelligent Land Measurement app loads', (
    WidgetTester tester,
  ) async {
    // Build the actual application.
    await tester.pumpWidget(const IntelligentLandMeasurementApp());

    // Verify that the app loads successfully.
    expect(find.text('Intelligent Land Measurement'), findsOneWidget);
  });
}
