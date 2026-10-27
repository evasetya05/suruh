import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_logo.dart';

/// Branded launch screen.
///
/// It does not navigate on a timer - the router's redirect holds every route
/// here until [AuthBloc] has resolved the session, then moves on by itself.
/// That avoids the classic race where a slow session restore lands the user on
/// the login screen and then yanks them to the home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ScaleTransition(
                scale: _scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(112 * 0.2237),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const AppLogo(size: 112),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: <Widget>[
                    Text(
                      AppConfig.instance.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppConfig.instance.tagline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConfig.instance.byline,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
