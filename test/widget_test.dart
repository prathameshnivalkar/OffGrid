import 'package:flutter_test/flutter_test.dart';
import 'package:offgrid_messenger/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OffGridMessengerApp(
      deviceId: 'test_device_id',
      deviceName: 'Test Device',
      isFirstLaunch: false,
    ));

    // Verify that the app starts without crashing
    expect(find.text('OffGrid Messenger'), findsOneWidget);
  });
}