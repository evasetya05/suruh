import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_cubit.dart';

/// Edit name, phone and avatar emoji.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<ProfileCubit>(
      create: (_) => buildProfileCubit(),
      child: _EditProfileView(user: user),
    );
  }
}

/// Shared factory so every profile screen wires the same eight use cases.
ProfileCubit buildProfileCubit() => ProfileCubit(
      getProfile: sl<GetProfile>(),
      updateProfile: sl<UpdateProfile>(),
      getAddresses: sl<GetAddresses>(),
      saveAddress: sl<SaveAddress>(),
      deleteAddress: sl<DeleteAddress>(),
      setDefaultAddress: sl<SetDefaultAddress>(),
      getFavourites: sl<GetFavouriteRestaurants>(),
      toggleFavourite: sl<ToggleFavourite>(),
    );

class _EditProfileView extends StatefulWidget {
  const _EditProfileView({required this.user});

  final User user;

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone);
  late String _emoji = widget.user.avatarEmoji;

  static const List<String> _avatars = <String>[
    '🙂', '👩🏻', '🧑🏽', '👨🏻', '🧕🏻', '👩🏽‍🦱', '🧑🏻‍💻', '👨🏾', '👩🏻‍🍳', '🧔🏽',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final User? updated = await context.read<ProfileCubit>().saveProfile(
          userId: widget.user.id,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          avatarEmoji: _emoji,
        );

    if (!mounted || updated == null) return;
    // Push the new user into the session so every screen reflects the change.
    context.read<AuthBloc>().add(AuthProfileRefreshed(updated));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState a, ProfileState b) =>
          a.errorMessage != b.errorMessage,
      listener: (BuildContext context, ProfileState state) {
        if (state.errorMessage == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
        context.read<ProfileCubit>().clearMessages();
      },
      builder: (BuildContext context, ProfileState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Personal information')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(context.gutter),
            child: ContentContainer(
              maxWidth: 520,
              padded: false,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _emoji,
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Choose an avatar', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _avatars.map((String emoji) {
                        final bool selected = emoji == _emoji;
                        return InkWell(
                          onTap: () => setState(() => _emoji = emoji),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: selected
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      label: 'Full name',
                      controller: _name,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Mobile number',
                      controller: _phone,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: Validators.phone,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Email',
                      controller:
                          TextEditingController(text: widget.user.email),
                      prefixIcon: Icons.alternate_email_rounded,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Email is tied to your login and cannot be changed here.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: 'Save changes',
                      isLoading: state.isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
