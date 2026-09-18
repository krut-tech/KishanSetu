import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://dpbuhtverikgcaieucdp.supabase.co',
        publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwYnVodHZlcmlrZ2NhaWV1Y2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxODcwMTUsImV4cCI6MjEwNDc2MzAxNX0.MfsPMFUMhUrNc46zwKpu_TEPhS5rLZShTiaXPgx6LoY',
        authOptions: const FlutterAuthClientOptions(localStorage: EmptyLocalStorage()),
      );
    } catch (_) {}
  });

  testWidgets('App initializes successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FarmerMarketApp(),
      ),
    );

    expect(find.byType(FarmerMarketApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
