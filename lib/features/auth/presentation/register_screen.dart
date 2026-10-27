import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  UserRole _role = UserRole.customer;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms to continue.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (AuthState a, AuthState b) =>
            a.errorMessage != b.errorMessage,
        listener: (BuildContext context, AuthState state) {
          if (state.errorMessage == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
              ),
            );
          context.read<AuthBloc>().add(const AuthMessageCleared());
        },
        builder: (BuildContext context, AuthState state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: ContentContainer(
              maxWidth: 460,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'A few details and you are in.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      label: 'Full name',
                      controller: _name,
                      hint: 'Aisyah Rahman',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                      autofillHints: const <String>[AutofillHints.name],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                      label: 'Mobile number',
                      controller: _phone,
                      hint: '012-345 6789',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: Validators.phone,
                      autofillHints: const <String>[
                        AutofillHints.telephoneNumber,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      hint: 'At least 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Confirm password',
                      controller: _confirm,
                      hint: 'Type it once more',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: (String? value) =>
                          Validators.confirmPassword(value, _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('I am joining as', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _RolePicker(
                      value: _role,
                      onChanged: (UserRole role) =>
                          setState(() => _role = role),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (bool? value) =>
                          setState(() => _acceptedTerms = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'I agree to the Terms of Service and Privacy Policy.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Create account',
                      isLoading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  static const Map<UserRole, (String, IconData)> _meta =
      <UserRole, (String, IconData)>{
    UserRole.customer: ('Customer', Icons.person_rounded),
    UserRole.restaurantPartner: ('Restaurant', Icons.storefront_rounded),
    UserRole.deliveryPartner: ('Rider', Icons.two_wheeler_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: UserRole.values.map((UserRole role) {
        final (String label, IconData icon) = _meta[role]!;
        final bool selected = role == value;
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => onChanged(role),
          avatar: Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : null,
          ),
          label: Text(label),
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
          showCheckmark: false,
        );
      }).toList(growable: false),
    );
  }
}
