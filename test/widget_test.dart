import 'package:flutter_test/flutter_test.dart';
import 'package:appa_pdf/main.dart';
import 'package:provider/provider.dart';
import 'package:appa_pdf/providers/file_provider.dart';

void main() {
  testWidgets('App renders cleanly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap in MultiProvider because AppaPDFApp expects it to be present in the tree
    // as seen in main.dart's runApp.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FileProvider()),
        ],
        child: const AppaPDFApp(),
      ),
    );

    // Verify that the SplashScreen is rendered by checking for the app name.
    expect(find.text('AppaPDF'), findsOneWidget);

    // Advance time to trigger the splash screen navigation timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
