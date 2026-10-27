import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Image surface used for every restaurant / dish visual in the app.
///
/// The demo ships without bundled photography and must run fully offline, so
/// when no [imageUrl] is available this renders a deterministic gradient plate
/// with the item's emoji. Same input always produces the same artwork, which
/// makes the UI look designed rather than like a broken image.
///
/// When a real backend supplies URLs (Firebase Storage), the same widget
/// transparently switches to [CachedNetworkImage] with a shimmer placeholder
/// and falls back to the generated plate on error.
class AppImage extends StatelessWidget {
  const AppImage({
    required this.seed,
    this.imageUrl,
    this.emoji,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.emojiScale = 0.45,
    super.key,
  });

  /// Stable string (usually an entity id or name) that drives the gradient.
  final String seed;
  final String? imageUrl;
  final String? emoji;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// Emoji size as a fraction of the shortest side.
  final double emojiScale;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(AppRadius.md);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null || imageUrl!.isEmpty
            ? _GeneratedPlate(seed: seed, emoji: emoji, emojiScale: emojiScale)
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: fit,
                width: width,
                height: height,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (BuildContext context, String url) =>
                    _GeneratedPlate(
                  seed: seed,
                  emoji: emoji,
                  emojiScale: emojiScale,
                ),
                errorWidget: (BuildContext context, String url, Object error) =>
                    _GeneratedPlate(
                  seed: seed,
                  emoji: emoji,
                  emojiScale: emojiScale,
                ),
              ),
      ),
    );
  }
}

class _GeneratedPlate extends StatelessWidget {
  const _GeneratedPlate({
    required this.seed,
    required this.emojiScale,
    this.emoji,
  });

  final String seed;
  final String? emoji;
  final double emojiScale;

  /// Warm, food-friendly gradient pairs. Chosen by hash so a dish keeps its
  /// look across rebuilds and sessions.
  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFFFFB36B), Color(0xFFFF7A45)],
    <Color>[Color(0xFF7BD8A6), Color(0xFF2FB37A)],
    <Color>[Color(0xFF9FC7FF), Color(0xFF5A8FE6)],
    <Color>[Color(0xFFFFC1D6), Color(0xFFF2749B)],
    <Color>[Color(0xFFD7C0FF), Color(0xFF9B7BE8)],
    <Color>[Color(0xFFFFE08A), Color(0xFFF5B93B)],
    <Color>[Color(0xFF9FE7E0), Color(0xFF39B7AC)],
    <Color>[Color(0xFFFFAFA3), Color(0xFFE8695B)],
  ];

  @override
  Widget build(BuildContext context) {
    final int hash = seed.hashCode.abs();
    final List<Color> palette = _palettes[hash % _palettes.length];
    final double angle = (hash % 360) * math.pi / 180;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double shortest = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 120,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 120,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette,
              begin: Alignment(math.cos(angle), math.sin(angle)),
              end: Alignment(-math.cos(angle), -math.sin(angle)),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Soft highlight blob so the plate is not a flat gradient.
              Positioned(
                left: -shortest * 0.2,
                top: -shortest * 0.25,
                child: Container(
                  width: shortest * 0.9,
                  height: shortest * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
              if (emoji != null && emoji!.isNotEmpty)
                Center(
                  child: Text(
                    emoji!,
                    style: TextStyle(
                      fontSize: math.max(14, shortest * emojiScale),
                      shadows: <Shadow>[
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
