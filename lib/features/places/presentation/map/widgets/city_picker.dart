import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../notifications/push_providers.dart';
import '../../../../notifications/push_service.dart';
import '../../../application/place_providers.dart';
import '../../../domain/city.dart';

/// Lets the user switch city. Resolves to the city they tapped, if any.
Future<City?> showCityPicker(BuildContext context) {
  return showModalBottomSheet<City>(
    context: context,
    useSafeArea: true,
    builder: (_) => const _CityPicker(),
  );
}

class _CityPicker extends ConsumerStatefulWidget {
  const _CityPicker();

  @override
  ConsumerState<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends ConsumerState<_CityPicker> {
  bool _busy = false;
  PushAvailability? _problem;

  Future<void> _setAlerts(bool enabled) async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final result = await ref
        .read(placeAlertsProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = result == PushAvailability.enabled ? null : result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedCityProvider);
    final userCity = ref.watch(userCityProvider);
    final places = ref.watch(placesProvider).value ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Choose a city', style: theme.textTheme.titleLarge),
          ),
          for (final city in City.values)
            _CityTile(
              city: city,
              placeCount: places.where((p) => p.city == city).length,
              selected: city == selected,
              isUserCity: city == userCity,
              onTap: () => Navigator.of(context).pop(city),
            ),
          const Divider(height: 24, indent: 20, endIndent: 20),
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('New place alerts'),
            subtitle: Text(switch (_problem) {
              PushAvailability.denied =>
                'Notifications are off for Spotly. Turn them on in Settings.',
              PushAvailability.unavailable =>
                'Notifications aren’t available in this build.',
              _ =>
                'Get a notification when a place opens in ${selected.label}.',
            }),
            value: ref.watch(placeAlertsProvider),
            onChanged: _busy ? null : _setAlerts,
          ),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.placeCount,
    required this.selected,
    required this.isUserCity,
    required this.onTap,
  });

  final City city;
  final int placeCount;
  final bool selected;
  final bool isUserCity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = [
      if (placeCount > 0) '$placeCount places',
      if (isUserCity) 'You’re here',
    ].join(' · ');

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isUserCity
                      ? Icons.near_me_rounded
                      : Icons.location_city_rounded,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city.label, style: theme.textTheme.titleMedium),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
