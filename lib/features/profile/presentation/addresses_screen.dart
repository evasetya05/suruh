import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_cubit.dart';
import 'edit_profile_screen.dart';

/// Saved delivery addresses with add / edit / delete / set-default.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<ProfileCubit>(
      create: (_) => buildProfileCubit()..loadAddresses(user.id),
      child: _AddressesView(userId: user.id),
    );
  }
}

class _AddressesView extends StatelessWidget {
  const _AddressesView({required this.userId});

  final String userId;

  Future<void> _openEditor(BuildContext context, {Address? existing}) async {
    final ProfileCubit cubit = context.read<ProfileCubit>();
    final Address? result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressForm(existing: existing),
    );
    if (result != null) await cubit.saveAddress(userId, result);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState a, ProfileState b) =>
          a.successMessage != b.successMessage ||
          a.errorMessage != b.errorMessage,
      listener: (BuildContext context, ProfileState state) {
        final String? message = state.errorMessage ?? state.successMessage;
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
        context.read<ProfileCubit>().clearMessages();
      },
      builder: (BuildContext context, ProfileState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Saved addresses')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add address'),
          ),
          body: state.addresses.isEmpty
              ? EmptyView(
                  title: 'No saved addresses',
                  message:
                      'Add one so checkout is a single tap next time.',
                  icon: Icons.location_off_outlined,
                  actionLabel: 'Add an address',
                  onAction: () => _openEditor(context),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    context.gutter,
                    AppSpacing.lg,
                    context.gutter,
                    AppSpacing.huge * 2,
                  ),
                  itemCount: state.addresses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int i) {
                    final Address address = state.addresses[i];
                    return ContentContainer(
                      padded: false,
                      child: _AddressCard(
                        address: address,
                        onEdit: () =>
                            _openEditor(context, existing: address),
                        onDelete: () => _confirmDelete(context, address),
                        onSetDefault: address.isDefault
                            ? null
                            : () => context
                                .read<ProfileCubit>()
                                .setDefaultAddress(userId, address.id),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Address address) async {
    final ProfileCubit cubit = context.read<ProfileCubit>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove this address?'),
        content: Text(address.formatted),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.deleteAddress(userId, address.id);
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  IconData get _icon => switch (address.label) {
        AddressLabel.home => Icons.home_outlined,
        AddressLabel.work => Icons.work_outline_rounded,
        AddressLabel.other => Icons.place_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(address.label.display, style: theme.textTheme.titleSmall),
              const SizedBox(width: AppSpacing.sm),
              if (address.isDefault)
                const InfoPill(
                  label: 'Default',
                  color: AppColors.primary,
                  filled: true,
                ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Address options',
                onSelected: (String action) => switch (action) {
                  'edit' => onEdit(),
                  'delete' => onDelete(),
                  'default' => onSetDefault?.call(),
                  _ => null,
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  if (onSetDefault != null)
                    const PopupMenuItem<String>(
                      value: 'default',
                      child: Text('Set as default'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(address.formatted, style: theme.textTheme.bodyMedium),
          if (address.notes != null && address.notes!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(Icons.sticky_note_2_outlined, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    address.notes!,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Add / edit form. Returns the composed [Address] via `Navigator.pop`.
class _AddressForm extends StatefulWidget {
  const _AddressForm({this.existing});

  final Address? existing;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _line1 =
      TextEditingController(text: widget.existing?.line1);
  late final TextEditingController _line2 =
      TextEditingController(text: widget.existing?.line2);
  late final TextEditingController _city =
      TextEditingController(text: widget.existing?.city ?? 'Kuala Lumpur');
  late final TextEditingController _postcode =
      TextEditingController(text: widget.existing?.postcode);
  late final TextEditingController _state = TextEditingController(
    text: widget.existing?.state ?? 'WP Kuala Lumpur',
  );
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes);

  late AddressLabel _label = widget.existing?.label ?? AddressLabel.home;
  late bool _isDefault = widget.existing?.isDefault ?? false;

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _postcode.dispose();
    _state.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      Address(
        // Reuse the id when editing so the repository updates in place.
        id: widget.existing?.id ??
            'addr-${DateTime.now().millisecondsSinceEpoch}',
        label: _label,
        line1: _line1.text.trim(),
        line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        city: _city.text.trim(),
        postcode: _postcode.text.trim(),
        state: _state.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        isDefault: _isDefault,
        latitude: widget.existing?.latitude,
        longitude: widget.existing?.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.existing == null ? 'Add address' : 'Edit address',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Label', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: AddressLabel.values.map((AddressLabel label) {
                    final bool selected = label == _label;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _label = label),
                      label: Text(label.display),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Address line 1',
                  controller: _line1,
                  hint: 'Unit, building or street',
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Address line 1'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Address line 2 (optional)',
                  controller: _line2,
                  hint: 'Area or landmark',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'City',
                        controller: _city,
                        textInputAction: TextInputAction.next,
                        validator: (String? v) =>
                            Validators.required(v, field: 'City'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Postcode',
                        controller: _postcode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (String? v) =>
                            Validators.required(v, field: 'Postcode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'State',
                  controller: _state,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.required(v, field: 'State'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Note for the rider (optional)',
                  controller: _notes,
                  hint: 'e.g. Leave at the guard house',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (bool? v) =>
                      setState(() => _isDefault = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Make this my default address'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Save address', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
