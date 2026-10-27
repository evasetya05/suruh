import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/promo.dart';

/// Auto-advancing promo banner carousel.
///
/// Auto-play stops permanently on the first manual swipe - continuing to move
/// the page under someone who is reading it is a common irritation.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({required this.promos, super.key});

  final List<Promo> promos;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.88);
  Timer? _autoPlay;
  int _index = 0;
  bool _userInteracted = false;

  List<Promo> get _visible => widget.promos
      .where((Promo p) => !p.isExpired)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlay = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted || _userInteracted || _visible.length < 2) return;
      final int next = (_index + 1) % _visible.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyCode(Promo promo) async {
    await Clipboard.setData(ClipboardData(text: promo.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Promo code ${promo.code} copied - use it at checkout'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<Promo> promos = _visible;
    if (promos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        SizedBox(
          height: 132,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (ScrollStartNotification notification) {
              if (notification.dragDetails != null) {
                _userInteracted = true;
                _autoPlay?.cancel();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: promos.length,
              onPageChanged: (int i) => setState(() => _index = i),
              itemBuilder: (BuildContext context, int i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _PromoBanner(
                  promo: promos[i],
                  onTap: () => _copyCode(promos[i]),
                ),
              ),
            ),
          ),
        ),
        if (promos.length > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(promos.length, (int i) {
              final bool active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 20 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.promo, required this.onTap});

  final Promo promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = AppColors.tintFor(promo.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[tint, tint.withValues(alpha: 0.72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (promo.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            promo.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        promo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code ${promo.code} • tap to copy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(promo.emoji, style: const TextStyle(fontSize: 46)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
