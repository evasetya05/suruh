import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/app/app.dart';
import 'package:food_delivery_app/app/di/service_locator.dart';
import 'package:food_delivery_app/core/config/app_config.dart';
import 'package:food_delivery_app/core/storage/local_storage.dart';
import 'package:food_delivery_app/data/datasources/local/demo_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the whole customer journey through the real app:
/// sign in -> open a restaurant -> add a dish -> cart -> checkout -> tracking.
///
/// This is the test that proves the layers are actually wired to each other.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppConfig.override(
      const AppConfig(
        simulatedLatency: Duration.zero,
        // Long enough that the order does not race ahead mid-assertion.
        orderStageDuration: Duration(seconds: 30),
      ),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorage.kOnboardingSeen: true,
    });
    DemoDataSource.instance.reset();
    await ServiceLocator.reset();
    await ServiceLocator.init();
  });

  tearDown(() async {
    DemoDataSource.instance.pauseSimulations();
    await ServiceLocator.reset();
    AppConfig.override(const AppConfig());
  });

  /// Shimmer and the promo carousel animate forever, so frames are pumped
  /// explicitly rather than settled.
  Future<void> frames(WidgetTester tester, {int count = 8}) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Winds the app down inside the test body: stops the backend simulation,
  /// disposes the tree so widgets cancel their timers, then flushes whatever
  /// is left. Doing this here rather than in a teardown means it runs before
  /// the binding's pending-timer assertion.
  Future<void> shutDown(WidgetTester tester) async {
    DemoDataSource.instance.pauseSimulations();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  }

  /// Sets up a 360x800 logical viewport - a typical phone - and disposes the
  /// tree afterwards so no bloc or timer outlives the test.
  void usePhoneViewport(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Teardowns run last-registered-first, and both must happen before the
    // binding's pending-timer check: stop the backend's delivery simulation,
    // then dispose the tree so the promo carousel cancels its auto-play timer.
    addTearDown(DemoDataSource.instance.pauseSimulations);
  }

  /// Scrolls [finder] into view before tapping it.
  ///
  /// The viewport is only 800dp tall, so most targets below the first screenful
  /// need this - tapping an off-screen widget silently does nothing.
  ///
  /// Widgets already in the tree are reached with `ensureVisible`, which walks
  /// up to whichever scrollable actually contains them. Only lazily-built list
  /// items that do not exist yet fall back to `scrollUntilVisible`.
  Future<void> scrollAndTap(
    WidgetTester tester,
    Finder finder, {
    int settleFrames = 8,
  }) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        140,
        scrollable: find.byType(Scrollable).first,
      );
    } else {
      await tester.ensureVisible(finder);
      await tester.pump();

      // `ensureVisible` parks the target at the very top of the viewport, where
      // a pinned app bar or tab bar sits on top of it and swallows the tap.
      // Nudge it back down into open space first.
      final Rect rect = tester.getRect(finder);
      if (rect.top < 240) {
        await tester.drag(finder, Offset(0, 240 - rect.top));
        await tester.pump();
      }
    }
    await tester.pump();
    await tester.tap(finder);
    await frames(tester, count: settleFrames);
  }

  testWidgets('customer can order a dish end to end',
      (WidgetTester tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(const MSDevBuildEatsApp());
    await frames(tester);

    // --- Sign in as the seeded customer -------------------------------------
    await scrollAndTap(tester, find.text('Aisyah - Customer'));

    expect(find.text('Featured this week'), findsOneWidget);

    // --- Open a restaurant from the featured rail ---------------------------
    await scrollAndTap(tester, find.text('Nasi Lemak Antarabangsa').first);

    expect(find.textContaining('Menu ('), findsOneWidget);
    expect(find.text('Nasi Lemak Ayam Goreng'), findsWidgets);

    // --- Add a dish through the add-to-cart sheet ---------------------------
    await scrollAndTap(
      tester,
      find.widgetWithText(OutlinedButton, 'Add').first,
      settleFrames: 5,
    );

    expect(find.text('Special instructions'), findsOneWidget);

    // Three of the RM 9.90 dish clears the RM 25 minimum spend on the promo
    // code applied further down.
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pump();

    await tester.tap(find.textContaining('Add •').last);
    await frames(tester, count: 5);

    // The sticky bar on the restaurant page now shows the basket.
    expect(find.text('View cart'), findsOneWidget);

    // --- Go to the cart -----------------------------------------------------
    await tester.tap(find.text('View cart'));
    await frames(tester, count: 5);

    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Ordering from'), findsOneWidget);

    // --- An unknown promo code is rejected ----------------------------------
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. MSDEV30'),
      'NOPECODE',
    );
    await scrollAndTap(
      tester,
      find.widgetWithText(FilledButton, 'Apply'),
      settleFrames: 5,
    );

    expect(find.textContaining('not a valid promo code'), findsOneWidget);

    // --- A real promo code applies and shows the saving ---------------------
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. MSDEV30'),
      'MSDEV30',
    );
    await scrollAndTap(
      tester,
      find.widgetWithText(FilledButton, 'Apply'),
      settleFrames: 6,
    );

    // Two matches: the applied-promo card and the confirmation snackbar.
    expect(find.textContaining('MSDEV30 applied'), findsWidgets);
    expect(find.textContaining('You saved'), findsOneWidget);

    // --- Checkout -----------------------------------------------------------
    await scrollAndTap(tester, find.text('Go to checkout'), settleFrames: 6);

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('GrabPay Wallet'), findsOneWidget);

    // --- Place the order ----------------------------------------------------
    await scrollAndTap(
      tester,
      find.textContaining('Place order •'),
      settleFrames: 10,
    );

    // --- Lands on live tracking ---------------------------------------------
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Delivering to'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Order placed'), findsWidgets);

    await shutDown(tester);
  });

  testWidgets('adding a dish from a second restaurant prompts to start over',
      (WidgetTester tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(const MSDevBuildEatsApp());
    await frames(tester);

    await scrollAndTap(tester, find.text('Aisyah - Customer'));

    // Basket from restaurant one.
    await scrollAndTap(tester, find.text('Nasi Lemak Antarabangsa').first);
    await scrollAndTap(
      tester,
      find.widgetWithText(OutlinedButton, 'Add').first,
      settleFrames: 5,
    );
    await tester.tap(find.textContaining('Add •').last);
    await frames(tester, count: 5);

    expect(find.text('View cart'), findsOneWidget);

    // Back to home, then into a different restaurant.
    await tester.pageBack();
    await frames(tester);

    await scrollAndTap(tester, find.text('Village Park Restaurant').first);
    await scrollAndTap(
      tester,
      find.widgetWithText(OutlinedButton, 'Add').first,
      settleFrames: 5,
    );
    await tester.tap(find.textContaining('Add •').last);
    await frames(tester, count: 5);

    // The cart bloc raises a conflict rather than quietly swapping baskets.
    expect(find.text('View cart'), findsNothing);

    await shutDown(tester);
  });

  testWidgets('search finds a seeded dish', (WidgetTester tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(const MSDevBuildEatsApp());
    await frames(tester);

    await scrollAndTap(tester, find.text('Aisyah - Customer'));

    await tester.tap(find.text('Search').first);
    await frames(tester, count: 6);

    expect(find.text('Trending in Kuala Lumpur'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ramen');
    // The bloc debounces for 320ms before querying, then the results render.
    await frames(tester, count: 12);

    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.textContaining('Ichiban Ramen House'), findsWidgets);

    await shutDown(tester);
  });
}
