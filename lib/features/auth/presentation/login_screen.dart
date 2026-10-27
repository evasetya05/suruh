import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/config/app_config.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/article_credit.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/demo_persona_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email =
      TextEditingController(text: 'customer@msdevbuild.com');
  final TextEditingController _password =
      TextEditingController(text: 'demo1234');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
  }

  void _forgotPassword() {
    final String? error = Validators.email(_email.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter your email first - $error')),
      );
      return;
    }
    context
        .read<AuthBloc>()
        .add(AuthPasswordResetRequested(_email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (AuthState a, AuthState b) =>
            a.errorMessage != b.errorMessage ||
            a.infoMessage != b.infoMessage,
        listener: (BuildContext context, AuthState state) {
          final String? message = state.errorMessage ?? state.infoMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor:
                    state.errorMessage != null ? AppColors.danger : null,
              ),
            );
          context.read<AuthBloc>().add(const AuthMessageCleared());
        },
        builder: (BuildContext context, AuthState state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: ContentContainer(
                maxWidth: 460,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _Brand(),
                      const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        'Welcome back',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign in to pick up where you left off.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppTextField(
                        label: 'Email',
                        controller: _email,
                        hint: 'you@example.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                        autofillHints: const <String>[AutofillHints.email],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        hint: 'Your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        validator: Validators.password,
                        onSubmitted: (_) => _submit(),
                        autofillHints: const <String>[AutofillHints.password],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              state.isSubmitting ? null : _forgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Sign in',
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Wrap rather than Row: at 360dp with large text the
                      // prompt and the button do not fit on one line.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            'New to ${AppConfig.instance.appName}?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.push(Routes.register),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _OrDivider(),
                      const SizedBox(height: AppSpacing.xl),
                      DemoPersonaPicker(
                        enabled: !state.isSubmitting,
                        onSelected: (UserRole role) => context
                            .read<AuthBloc>()
                            .add(AuthDemoSignInRequested(role)),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const ArticleCredit(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return AppLogoWordmark(
      title: AppConfig.instance.appName,
      subtitle: AppConfig.instance.tagline,
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        // Flexible so a long label or large text scale shrinks the label
        // rather than overflowing the row.
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'or explore a demo persona',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
