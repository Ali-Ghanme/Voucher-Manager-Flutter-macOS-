import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/voucher_model.dart';

/// Big bold typography panel showing the currently-selected/just-sold
/// vouchers so an operator can quickly re-type them into an SMS app on
/// their phone. Designed to be readable at a glance from arm's length.
class VoucherDisplayPanel extends StatelessWidget {
  final List<Voucher> vouchers;

  const VoucherDisplayPanel({super.key, required this.vouchers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (vouchers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withOpacity(0.12)),
        ),
        alignment: Alignment.center,
        child: Text(
          'لا توجد بطاقات محددة بعد\nاختر عدد البطاقات للبيع',
          textAlign: TextAlign.center,
          style: TextStyle(color: onSurface.withOpacity(0.54), fontSize: 16),
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 180.h),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.primaryColor.withOpacity(0.4), width: 1.5),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: vouchers.length,
        separatorBuilder: (_, __) =>
            Divider(color: onSurface.withOpacity(0.12), height: 28),
        itemBuilder: (context, index) {
          final v = vouchers[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vouchers.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'بطاقة ${index + 1}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: onSurface.withOpacity(0.5)),
                  ),
                ),
              _VoucherField(
                label: 'يوزر',
                value: v.username,
                accentColor: const Color(0xFF4FC3F7), // blue
              ),
              const SizedBox(height: 12),
              _VoucherField(
                label: 'باسورد',
                value: v.password,
                accentColor: const Color(0xFFFFB74D), // orange
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single tap-to-copy username/password field, tuned for legibility
/// when reading digits off-screen to retype into an SMS app:
/// monospaced font, wide letter-spacing, high contrast, and a distinct
/// accent color per field type so username/password are never confused
/// at a glance.
class _VoucherField extends StatefulWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _VoucherField({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  State<_VoucherField> createState() => _VoucherFieldState();
}

class _VoucherFieldState extends State<_VoucherField> {
  bool _justCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  /// Inserts a hair space between every character so long digit runs
  /// don't visually blur together.
  String get _spacedValue => widget.value.split('').join('\u2009');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.accentColor.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accentColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SelectableText(
                        _spacedValue,
                        style: TextStyle(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _justCopied ? Icons.check_circle : Icons.copy_rounded,
                color: _justCopied ? Colors.yellow : widget.accentColor,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
