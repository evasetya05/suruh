import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/theme/app_theme.dart';
import 'package:food_delivery_app/core/widgets/app_button.dart';
import 'package:food_delivery_app/core/widgets/common_widgets.dart';
import 'package:food_delivery_app/core/widgets/state_views.dart';

/// Widget tests for the reusable pieces every screen leans on. If these break,
/// loading / empty / error handling breaks everywhere at once.
void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: child),
      );

  group('EmptyView', () {
    testWidgets('renders its copy and fires the action', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(
        wrap(
          EmptyView(
            title: 'Your cart is empty',
            message: 'Add a dish to get started.',
            actionLabel: 'Browse',
            onAction: () => taps++,
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add a dish to get started.'), findsOneWidget);

      await tester.tap(find.text('Browse'));
      expect(taps, 1);
    });

    testWidgets('hides the action when no callback is given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(const EmptyView(title: 'Nothing here', actionLabel: 'Browse')),
      );

      expect(find.text('Browse'), findsNothing);
    });
  });

  group('ErrorView', () {
    testWidgets('offers retry and calls back', (WidgetTester tester) async {
      int retries = 0;

      await tester.pumpWidget(
        wrap(
          ErrorView(
            message: 'No connection',
            onRetry: () => retries++,
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('No connection'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('omits retry when there is nothing to retry',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ErrorView(message: 'Fatal')));
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('AppButton', () {
    testWidgets('swaps its label for a spinner while loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const AppButton(label: 'Place order', isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Place order'), findsNothing);
    });

    testWidgets('does not fire while loading', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(
        wrap(
          AppButton(
            label: 'Place order',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 0);
    });

    testWidgets('fires when idle and enabled', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(
        wrap(AppButton(label: 'Place order', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Place order'));
      expect(taps, 1);
    });
  });

  group('QuantityStepper', () {
    testWidgets('increments and decrements', (WidgetTester tester) async {
      int quantity = 2;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                QuantityStepper(
              quantity: quantity,
              onIncrement: () => setState(() => quantity++),
              onDecrement: () => setState(() => quantity--),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows a delete icon at the minimum quantity',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          QuantityStepper(
            quantity: 1,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsNothing);
    });
  });

  group('Dark theme', () {
    testWidgets('every state view renders without overflow in dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: <Widget>[
              Expanded(child: EmptyView(title: 'Empty')),
              Expanded(child: ErrorView(message: 'Broken')),
            ],
          ),
          theme: AppTheme.dark,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Broken'), findsOneWidget);
    });
  });
}
