import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/datasources/local/seed/seed_categories.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/partner_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/partner_bloc.dart';
import 'partner_dashboard_screen.dart';

/// Add or edit a dish.
///
/// One screen for both: [itemId] being null means "create", otherwise the form
/// is pre-filled from the loaded menu.
class MenuEditorScreen extends StatelessWidget {
  const MenuEditorScreen({this.itemId, super.key});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'Not signed in.'));
    }

    return BlocProvider<PartnerBloc>(
      create: (_) => buildPartnerBloc()..add(PartnerStarted(user.id)),
      child: _MenuEditorView(itemId: itemId),
    );
  }
}

class _MenuEditorView extends StatelessWidget {
  const _MenuEditorView({this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartnerBloc, PartnerState>(
      listenWhen: (PartnerState a, PartnerState b) =>
          a.successMessage != b.successMessage ||
          a.errorMessage != b.errorMessage,
      listener: (BuildContext context, PartnerState state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
              ),
            );
          context.read<PartnerBloc>().add(const PartnerMessageCleared());
          return;
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.successMessage!)));
          context.read<PartnerBloc>().add(const PartnerMessageCleared());
          Navigator.of(context).maybePop();
        }
      },
      builder: (BuildContext context, PartnerState state) {
        if (state.isLoading || state.restaurant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dish')),
            body: const LoadingView(),
          );
        }

        final FoodItem? existing = itemId == null
            ? null
            : state.menu.where((FoodItem i) => i.id == itemId).firstOrNull;

        return _EditorForm(
          existing: existing,
          restaurantId: state.restaurant!.id,
          isSaving: state.isSaving,
        );
      },
    );
  }
}

class _EditorForm extends StatefulWidget {
  const _EditorForm({
    required this.restaurantId,
    required this.isSaving,
    this.existing,
  });

  final FoodItem? existing;
  final String restaurantId;
  final bool isSaving;

  @override
  State<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends State<_EditorForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name);
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description);
  late final TextEditingController _price = TextEditingController(
    text: widget.existing?.priceMyr.toStringAsFixed(2),
  );
  late final TextEditingController _discount = TextEditingController(
    text: widget.existing?.discountPriceMyr?.toStringAsFixed(2),
  );
  late final TextEditingController _ingredients = TextEditingController(
    text: widget.existing?.ingredients.join(', '),
  );
  late final TextEditingController _prep = TextEditingController(
    text: '${widget.existing?.prepMinutes ?? 15}',
  );

  late String _categoryId = widget.existing?.categoryId ?? 'malaysian';
  late String _emoji = widget.existing?.emoji ?? '🍽️';
  late bool _isVegetarian = widget.existing?.isVegetarian ?? false;
  late bool _isSpicy = widget.existing?.isSpicy ?? false;

  bool get _isEditing => widget.existing != null;

  static const List<String> _emojiChoices = <String>[
    '🍽️', '🍛', '🍕', '🍔', '🍜', '🍣', '🥟', '🍗', '🍰', '🧋',
    '🥗', '🍤', '🌶️', '🥘', '🍚', '🍧', '☕', '🥐', '🍹', '🥩',
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _discount.dispose();
    _ingredients.dispose();
    _prep.dispose();
    super.dispose();
  }

  List<String> get _parsedIngredients => _ingredients.text
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final double price = double.parse(_price.text.trim());
    final double? discount = _discount.text.trim().isEmpty
        ? null
        : double.tryParse(_discount.text.trim());
    final int prepMinutes = int.tryParse(_prep.text.trim()) ?? 15;

    final PartnerBloc bloc = context.read<PartnerBloc>();

    if (_isEditing) {
      bloc.add(
        PartnerMenuItemUpdated(
          widget.existing!.copyWith(
            name: _name.text.trim(),
            description: _description.text.trim(),
            priceMyr: price,
            discountPriceMyr: discount,
            // An emptied discount field must actually clear the offer.
            clearDiscount: discount == null,
            categoryId: _categoryId,
            emoji: _emoji,
            ingredients: _parsedIngredients,
            isVegetarian: _isVegetarian,
            isSpicy: _isSpicy,
            spiceLevel: _isSpicy ? 2 : 0,
            prepMinutes: prepMinutes,
          ),
        ),
      );
    } else {
      bloc.add(
        PartnerMenuItemCreated(
          CreateMenuItemParams(
            restaurantId: widget.restaurantId,
            name: _name.text.trim(),
            description: _description.text.trim(),
            priceMyr: price,
            discountPriceMyr: discount,
            categoryId: _categoryId,
            emoji: _emoji,
            ingredients: _parsedIngredients,
            isVegetarian: _isVegetarian,
            isSpicy: _isSpicy,
            prepMinutes: prepMinutes,
          ),
        ),
      );
    }
  }

  /// Offer price has to be below the normal price, and the domain rejects it
  /// too - this just catches it before a round-trip.
  String? _validateDiscount(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    final double? parsed = double.tryParse(input);
    if (parsed == null) return 'Enter a number';
    final double? price = double.tryParse(_price.text.trim());
    if (price != null && parsed >= price) {
      return 'Must be lower than the normal price';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit dish' : 'Add a dish')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          AppSpacing.lg,
          context.gutter,
          AppSpacing.huge,
        ),
        child: ContentContainer(
          maxWidth: 560,
          padded: false,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: AppImage(
                    seed: widget.existing?.id ?? _name.text,
                    emoji: _emoji,
                    height: 96,
                    width: 96,
                    emojiScale: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Pick an icon', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _emojiChoices.map((String emoji) {
                    final bool selected = emoji == _emoji;
                    return InkWell(
                      onTap: () => setState(() => _emoji = emoji),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.16)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Dish name',
                  controller: _name,
                  hint: 'e.g. Nasi Lemak Ayam Goreng',
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Dish name'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Description',
                  controller: _description,
                  hint: 'What makes this dish worth ordering?',
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.required(v, field: 'Description'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        label: 'Price (RM)',
                        controller: _price,
                        hint: '12.90',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: Validators.price,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Offer price (optional)',
                        controller: _discount,
                        hint: '9.90',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateDiscount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Category', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: kSeedCategories.map((dynamic category) {
                    final bool selected = category.id == _categoryId;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _categoryId = category.id as String),
                      label: Text('${category.emoji} ${category.name}'),
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
                  label: 'Ingredients',
                  controller: _ingredients,
                  hint: 'Comma separated, e.g. Coconut rice, Chicken, Sambal',
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Prep time (minutes)',
                  controller: _prep,
                  hint: '15',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  value: _isVegetarian,
                  onChanged: (bool v) => setState(() => _isVegetarian = v),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vegetarian'),
                  dense: true,
                ),
                SwitchListTile(
                  value: _isSpicy,
                  onChanged: (bool v) => setState(() => _isSpicy = v),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Spicy'),
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _isEditing ? 'Save changes' : 'Add to menu',
                  isLoading: widget.isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
