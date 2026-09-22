import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../application/place_providers.dart';
import '../../../domain/place_category.dart';
import '../../common/category_visuals.dart';

/// A horizontal row under the search bar: the city switcher, then the
/// category filters.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({
    super.key,
    required this.onChanged,
    required this.onCityTap,
  });

  final VoidCallback onChanged;
  final VoidCallback onCityTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(placeFilterProvider.select((f) => f.category));
    final city = ref.watch(selectedCityProvider);
    final theme = Theme.of(context);

    void select(PlaceCategory? category) {
      ref.read(placeFilterProvider.notifier).toggleCategory(category);
      onChanged();
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: PlaceCategory.values.length + 2,
        separatorBuilder: (_, index) => index == 0
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Container(
                    width: 1,
                    height: 22,
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            : const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: city.label,
              icon: Icons.place_rounded,
              trailing: Icons.expand_more_rounded,
              semanticLabel: 'City: ${city.label}. Change city',
              color: theme.colorScheme.primary,
              onColor: theme.colorScheme.onPrimary,
              selected: false,
              onTap: onCityTap,
            );
          }
          if (index == 1) {
            return _Chip(
              label: 'All',
              icon: Icons.apps_rounded,
              color: theme.colorScheme.primary,
              onColor: theme.colorScheme.onPrimary,
              selected: selected == null,
              onTap: () => select(null),
            );
          }
          final category = PlaceCategory.values[index - 2];
          return _Chip(
            label: category.pluralLabel,
            icon: category.icon,
            color: context.palette.category(category),
            onColor: Colors.white,
            selected: selected == category,
            onTap: () => select(category),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final String? semanticLabel;
  final Color color;
  final Color onColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = selected ? onColor : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? '$label filter',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? color : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? theme.colorScheme.outline : Colors.transparent),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withValues(alpha: 0.35)
                  : context.palette.shadow,
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: selected ? onColor : color),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: 2),
                    Icon(trailing, size: 18, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
