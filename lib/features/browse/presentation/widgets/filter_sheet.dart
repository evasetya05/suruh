import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../domain/repositories/catalog_repository.dart';

/// Bottom sheet for sort + filter.
///
/// Edits a local copy and only returns it on "Show results", so backing out
/// leaves the listing untouched.
class FilterSheet extends StatefulWidget {
  const FilterSheet({required this.initial, super.key});

  final RestaurantFilter initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late RestaurantFilter _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('Filter & sort', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _draft = const RestaurantFilter()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Sort by', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: RestaurantSort.values.map((RestaurantSort sort) {
                  final bool selected = _draft.sort == sort;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(sort: sort)),
                    label: Text(sort.label),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                  );
                }).toList(growable: false),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('Show only', style: theme.textTheme.labelLarge),
              SwitchListTile(
                value: _draft.freeDeliveryOnly,
                onChanged: (bool value) => setState(
                  () => _draft = _draft.copyWith(freeDeliveryOnly: value),
                ),
                contentPadding: EdgeInsets.zero,
                title: const Text('Free delivery'),
                dense: true,
              ),
              SwitchListTile(
                value: _draft.openNowOnly,
                onChanged: (bool value) => setState(
                  () => _draft = _draft.copyWith(openNowOnly: value),
                ),
                contentPadding: EdgeInsets.zero,
                title: const Text('Open now'),
                dense: true,
              ),

              const SizedBox(height: AppSpacing.lg),
              Text('Minimum rating', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <double?>[null, 3.5, 4.0, 4.5].map((double? value) {
                  final bool selected = _draft.minRating == value;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(
                      () => _draft = value == null
                          ? _draft.copyWith(clearMinRating: true)
                          : _draft.copyWith(minRating: value),
                    ),
                    label: Text(value == null ? 'Any' : '$value+'),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                  );
                }).toList(growable: false),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text('Price level', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <int?>[null, 1, 2, 3].map((int? value) {
                  final bool selected = _draft.maxPriceLevel == value;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(
                      () => _draft = value == null
                          ? _draft.copyWith(clearMaxPriceLevel: true)
                          : _draft.copyWith(maxPriceLevel: value),
                    ),
                    label: Text(value == null ? 'Any' : 'RM' * value),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                  );
                }).toList(growable: false),
              ),

              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Show results',
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
