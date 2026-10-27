import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/app/app.dart';
import 'package:food_delivery_app/app/di/service_locator.dart';
import 'package:food_delivery_app/core/config/app_config.dart';
import 'package:food_delivery_app/core/storage/local_storage.dart';
import 'package:food_delivery_app/data/datasources/local/demo_data_source.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_users.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app - real DI graph, real router, real blocs, real demo
/// backend - and walks the primary flows. This is the test that would catch a
/// broken wiring change that unit tests happily pass through.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppConfig.override(
      const AppConfig(
        simulatedLatency: Duration.zero,
        orderStageDuration: Duration(seconds: 30),
      ),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DemoDataSource.instance.reset();
    await ServiceLocator.reset();
    await ServiceLocator.init();
  });

  tearDown(() async {
    // The demo backend advances orders on timers; leaving one running would
    // outlive the test and trip the pending-timer check.
    DemoDataSource.instance.pauseSimulations();
    await ServiceLocator.reset();
    AppConfig.override(const AppConfig());
  });

  /// Pumps the app and settles the splash -> onboarding/login redirect.
  ///
  /// The surface is sized to a tall phone so the sign-in screen's persona
  /// picker is reachable without every test scrolling first.
  Future<void> boot(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Tearing the tree down disposes the app's blocs and cancels the promo
    // carousel's auto-play timer.
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    await tester.pumpWidget(const MSDevBuildEatsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Advances several frames.
  ///
  /// `pumpAndSettle` cannot be used on the customer screens: the shimmer
  /// placeholders and the promo carousel animate continuously, so the tree
  /// never reaches a steady state.
  Future<void> pumpFrames(WidgetTester tester, {int frames = 8}) async {
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Signs in as a demo persona, scrolling the picker into view first.
  Future<void> signInAs(WidgetTester tester, String personaLabel) async {
    await tester.scrollUntilVisible(
      find.text(personaLabel),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(personaLabel));
    await pumpFrames(tester);
  }

  /// Marks onboarding as already seen and rebuilds the DI graph.
  Future<void> asReturningVisitor() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorage.kOnboardingSeen: true,
    });
    await ServiceLocator.reset();
    await ServiceLocator.init();
  }

  testWidgets('cold start lands on onboarding for a first-time visitor',
      (WidgetTester tester) async {
    await boot(tester);

    expect(find.text('Skip'), findsOneWidget);
    expect(find.textContaining('Everything you crave'), findsOneWidget);
  });

  testWidgets('a returning visitor goes straight to sign-in',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('signing in as the customer persona renders the home feed',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    await signInAs(tester, 'Aisyah - Customer');

    // Greeting, category strip and a seeded restaurant should all be present.
    expect(find.textContaining('Aisyah'), findsWidgets);
    expect(find.text('What are you craving?'), findsOneWidget);
    expect(find.text('Featured this week'), findsOneWidget);
    expect(find.textContaining('Nasi Lemak Antarabangsa'), findsWidgets);
  });

  testWidgets('signing in with the seeded credentials works',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'customer@msdevbuild.com',
    );
    await tester.enterText(find.byType(TextFormField).last, kDemoPassword);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await pumpFrames(tester);

    expect(find.text('What are you craving?'), findsOneWidget);
  });

  testWidgets('a wrong password shows an error and stays on sign-in',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'customer@msdevbuild.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Incorrect password'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('the restaurant partner persona lands on the merchant dashboard',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    await signInAs(tester, 'Wei Jian - Restaurant');

    expect(find.text('Merchant dashboard'), findsOneWidget);
    expect(find.text('Incoming orders'), findsOneWidget);
    expect(find.text('Manage menu'), findsOneWidget);
  });

  testWidgets('the rider persona lands on the delivery dashboard',
      (WidgetTester tester) async {
    await asReturningVisitor();
    await boot(tester);

    await signInAs(tester, 'Muthu - Rider');

    expect(find.text('Rider dashboard'), findsOneWidget);
    expect(find.text('Active deliveries'), findsOneWidget);
  });
}
