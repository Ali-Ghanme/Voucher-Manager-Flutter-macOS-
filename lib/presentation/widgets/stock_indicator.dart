import 'package:flutter/material.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';

/// Progress bar + textual count showing how much stock remains in the
/// active batch, e.g. "14 / 100 remaining".
class StockIndicator extends StatelessWidget {
  final int total;
  final int sold;

  const StockIndicator({super.key, required this.total, required this.sold});

  int get remaining => (total - sold).clamp(0, total);
  double get progress => total == 0 ? 0 : sold / total;

  Color _colorForRemaining(BuildContext context) {
    if (total == 0) return Theme.of(context).disabledColor;
    final ratio = remaining / total;
    if (ratio <= 0.1) return AppColors.aleart;
    if (ratio <= 0.25) return AppColors.warning;
    return AppColors.mainColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForRemaining(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$remaining / $total متبقٍ',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge!.copyWith(color: color),
        ),
      ],
    );
  }
}
