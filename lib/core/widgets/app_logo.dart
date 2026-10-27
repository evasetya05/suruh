import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The MSDevBuild Eats logo, drawn vectorially.
///
/// Painted rather than loaded from an asset so it stays crisp at any size, tints
/// to any colour, and costs nothing to bundle. The geometry is identical to
/// `assets/logo/logo.svg` and to the launcher icons produced by
/// `tool/generate_icons.py` - change one and change all three.
class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 48,
    this.showPlate = true,
    this.markColor,
    super.key,
  });

  /// Width and height of the square mark.
  final double size;

  /// Whether to draw the green rounded-square plate behind the monogram.
  /// Set to `false` to place the mark on an existing coloured surface.
  final bool showPlate;

  /// Overrides the monogram colour. Defaults to white on a plate, and the
  /// brand green without one.
  final Color? markColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LogoPainter(
          showPlate: showPlate,
          markColor: markColor ??
              (showPlate ? Colors.white : AppColors.primary),
        ),
      ),
    );
  }
}

/// Logo plus wordmark, used on the splash and sign-in screens.
class AppLogoWordmark extends StatelessWidget {
  const AppLogoWordmark({
    required this.title,
    this.subtitle,
    this.markSize = 48,
    this.onDarkBackground = false,
    this.axis = Axis.horizontal,
    super.key,
  });

  final String title;
  final String? subtitle;
  final double markSize;

  /// Inverts the type colours for use on the brand green.
  final bool onDarkBackground;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool vertical = axis == Axis.vertical;

    final Color titleColor =
        onDarkBackground ? Colors.white : theme.colorScheme.onSurface;
    final Color subtitleColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.86)
        : (theme.textTheme.bodySmall?.color ?? titleColor);

    final Widget text = Column(
      crossAxisAlignment:
          vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          textAlign: vertical ? TextAlign.center : TextAlign.start,
          style: (vertical
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(color: titleColor, fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            textAlign: vertical ? TextAlign.center : TextAlign.start,
            style: (vertical
                    ? theme.textTheme.bodyLarge
                    : theme.textTheme.bodySmall)
                ?.copyWith(color: subtitleColor),
          ),
        ],
      ],
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppLogo(size: markSize, showPlate: !onDarkBackground),
          const SizedBox(height: AppSpacing.xxl),
          text,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppLogo(size: markSize),
        const SizedBox(width: AppSpacing.md),
        Flexible(child: text),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.showPlate, required this.markColor});

  final bool showPlate;
  final Color markColor;

  // Fractions of the icon's side, shared with logo.svg and generate_icons.py.
  static const double _cornerRadius = 0.2237;
  static const double _stroke = 0.1120;
  static const double _mLeft = 0.2600;
  static const double _mRight = 0.7400;
  static const double _mTop = 0.3050;
  static const double _mBottom = 0.6250;
  static const double _mValleyY = 0.5250;
  static const double _dotCentreY = 0.7620;
  static const double _dotRadius = 0.0610;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    if (s <= 0) return;

    if (showPlate) {
      final Rect plate = Offset.zero & Size(s, s);
      canvas.drawRRect(
        RRect.fromRectAndRadius(plate, Radius.circular(_cornerRadius * s)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0xFF00C75A), AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(plate),
      );
    }

    // The "M": one polyline, round caps and joins.
    final Path monogram = Path()
      ..moveTo(_mLeft * s, _mBottom * s)
      ..lineTo(_mLeft * s, _mTop * s)
      ..lineTo(0.5 * s, _mValleyY * s)
      ..lineTo(_mRight * s, _mTop * s)
      ..lineTo(_mRight * s, _mBottom * s);

    canvas.drawPath(
      monogram,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = markColor
        ..isAntiAlias = true,
    );

    canvas.drawCircle(
      Offset(0.5 * s, _dotCentreY * s),
      _dotRadius * s,
      Paint()
        ..color = AppColors.accentOrange
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.showPlate != showPlate || oldDelegate.markColor != markColor;
}
