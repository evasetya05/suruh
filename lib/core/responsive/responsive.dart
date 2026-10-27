import 'package:flutter/widgets.dart';

/// Device size buckets used to adapt layout for phone / tablet / desktop web.
enum DeviceType { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1100;

  /// Content never stretches wider than this on large web windows - long line
  /// lengths are the fastest way to make a mobile-first app look broken.
  static const double maxContentWidth = 1180;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  DeviceType get deviceType {
    final double width = screenWidth;
    if (width >= Breakpoints.desktop) return DeviceType.desktop;
    if (width >= Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isWide => !isMobile;

  /// Horizontal page padding that grows with the viewport.
  double get gutter => switch (deviceType) {
        DeviceType.mobile => 16,
        DeviceType.tablet => 24,
        DeviceType.desktop => 32,
      };

  /// Column count for food/restaurant grids.
  int get gridColumns => switch (deviceType) {
        DeviceType.mobile => 2,
        DeviceType.tablet => 3,
        DeviceType.desktop => 4,
      };

  /// Picks a value per device type without a chain of if-statements.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      switch (deviceType) {
        DeviceType.mobile => mobile,
        DeviceType.tablet => tablet ?? mobile,
        DeviceType.desktop => desktop ?? tablet ?? mobile,
      };
}

/// Renders a different subtree per breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) => switch (context.deviceType) {
        DeviceType.mobile => mobile(context),
        DeviceType.tablet => (tablet ?? mobile)(context),
        DeviceType.desktop => (desktop ?? tablet ?? mobile)(context),
      };
}

/// Centres and width-caps its child so the app reads well in a maximised
/// browser window while staying edge-to-edge on phones.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padded = true,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padded
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: context.gutter),
                child: child,
              )
            : child,
      ),
    );
  }
}
