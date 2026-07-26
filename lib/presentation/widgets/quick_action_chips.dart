import 'package:flutter/material.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';

import '../../core/constants/app_constants.dart';

/// Row of quick-dispense chips: [1] [2] [5] [10] [20] plus a "custom"
/// entry point for arbitrary quantities.
class QuickActionChips extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final VoidCallback onCustom;
  final int maxAvailable;

  const QuickActionChips({
    super.key,
    required this.onSelect,
    required this.onCustom,
    required this.maxAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final n in AppConstants.quickDispenseOptions)
          _QuickChip(
            label: '$n',
            enabled: maxAvailable >= n,
            onTap: () => onSelect(n),
          ),
        _QuickChip(
          label: 'مخصص',
          enabled: maxAvailable > 0,
          onTap: onCustom,
          isCustom: true,
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool isCustom;

  const _QuickChip({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // Chip accent: orange for normal, yellow/warning for custom
    final accentColor = isCustom ? AppColors.warning : AppColors.mainColor;

    return Material(
      color: enabled
          ? accentColor.withOpacity(0.15)
          : onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? accentColor
                  : onSurface.withOpacity(0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: enabled ? onSurface : theme.disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
