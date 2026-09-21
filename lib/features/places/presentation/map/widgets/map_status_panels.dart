import 'package:flutter/material.dart';

import '../../../application/place_providers.dart';
import '../../common/floating_surface.dart';

/// "12 pharmacies · List" shown when nothing is selected.
class ResultsSummary extends StatelessWidget {
  const ResultsSummary({
    super.key,
    required this.count,
    required this.filter,
    required this.onShowList,
  });

  final int count;
  final PlaceFilter filter;
  final VoidCallback onShowList;

  String get _label {
    final category = filter.category;
    final noun = category == null
        ? (count == 1 ? 'place' : 'places')
        : (count == 1 ? category.label : category.pluralLabel).toLowerCase();
    final query = filter.query.trim();
    return query.isEmpty ? '$count $noun' : '$count $noun for “$query”';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingSurface(
      radius: 18,
      onTap: onShowList,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap a pin to preview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'List',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a search or filter matches nothing.
class EmptyResultsPanel extends StatelessWidget {
  const EmptyResultsPanel({
    super.key,
    required this.filter,
    required this.onClear,
  });

  final PlaceFilter filter;
  final VoidCallback onClear;

  String get _message {
    final query = filter.query.trim();
    final category = filter.category;
    if (category != null && query.isNotEmpty) {
      return 'No ${category.pluralLabel.toLowerCase()} match “$query”. '
          'Try another word or a different category.';
    }
    if (query.isNotEmpty) {
      return 'Nothing matches “$query” yet. Try “salon”, “jollof” or '
          '“pharmacy”.';
    }
    return 'There are no places in this category yet.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingSurface(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const _IconBadge(icon: Icons.search_off_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No matches', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

class LoadErrorPanel extends StatelessWidget {
  const LoadErrorPanel({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingSurface(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _IconBadge(
              icon: Icons.cloud_off_rounded,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Couldn’t load places',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check your connection and try again.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FloatingSurface(
        radius: 30,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Finding places around Lagos…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: tint),
    );
  }
}
