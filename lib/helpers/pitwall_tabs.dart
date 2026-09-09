import 'package:flutter/material.dart';
import 'package:boxbox/theme/pitwall_theme.dart';

/// Shared calendar and standings selector; follows the active brightness.
class PitwallTabs extends StatelessWidget {
  final List<String> labels;
  const PitwallTabs({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    final theme = buildPitwallTheme(Theme.of(context).brightness);
    return Theme(
        data: theme,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                tabs: [
                  for (final label in labels) Tab(text: label),
                ],
              ),
            ),
          ),
        ));
  }
}
