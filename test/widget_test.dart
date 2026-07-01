import 'package:flutter_test/flutter_test.dart';
import 'package:rental_report/main.dart';

void main() {
  testWidgets('renders empty home state content', (tester) async {
    await tester.pumpWidget(
      RentalReportApp(
        launchConfig: const AppLaunchConfig(),
        model: AppModel.empty(),
      ),
    );

    expect(
      find.text('Move-in reports that look\nclear, fast, and credible.'),
      findsOneWidget,
    );
    expect(find.text('Start New Inspection'), findsOneWidget);
    expect(find.text('No inspections yet'), findsOneWidget);
  });
}
