import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';

class _Page {
  const _Page({
    required this.emoji,
    required this.title,
    required this.body,
    required this.tint,
  });

  final String emoji;
  final String title;
  final String body;
  final Color tint;
}

const List<_Page> _pages = <_Page>[
  _Page(
    emoji: '✨',
    title: 'Ada Urusan?\nSuruh Kami!',
    body: 'Platform jasa on-demand serba bisa di Pontianak. Mau suruh kirim barang, belanja, antri tiket, atau urusan apa saja, serahkan pada kami!',
    tint: AppColors.primary,
  ),
  _Page(
    emoji: '🛵',
    title: 'Bisa Suruh Apa Saja,\nKapan Saja',
    body: 'Butuh bantuan cepat? Tulis instruksi tugasmu atau pilih layanan, mitra terdekat siap langsung meluncur menyelesaikannya.',
    tint: AppColors.accentOrange,
  ),
  _Page(
    emoji: '📍',
    title: 'Pantau Real-Time\n& Transparan',
    body: 'Lacak proses pekerjaan mulai dari pencarian mitra, penawaran harga, penugasan, hingga pesanan selesai dengan aman.',
    tint: AppColors.accentBlue,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Records that onboarding has been seen so the router sends returning users
  /// straight to sign-in.
  Future<void> _finish() async {
    await sl<LocalStorage>().setBool(LocalStorage.kOnboardingSeen, value: true);
    if (mounted) context.go(Routes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 560,
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (int i) => setState(() => _index = i),
                  itemBuilder: (BuildContext context, int i) {
                    final _Page page = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            color: page.tint.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            page.emoji,
                            style: const TextStyle(fontSize: 84),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_pages.length, (int i) {
                  final bool active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: active ? 26 : 7,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: _isLast ? 'Get started' : 'Continue',
                icon: _isLast ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
