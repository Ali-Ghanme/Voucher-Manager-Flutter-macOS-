import 'package:flutter/material.dart';

import '../../data/models/batch_model.dart';

/// Modal shown when the active batch's last voucher has just been sold.
/// Shows a human-readable "sold out in X days, Y hours" duration and a
/// primary CTA to import the next PDF batch.
class BatchCompletionDialog extends StatelessWidget {
  final BatchModel batch;
  final VoidCallback onImportNext;

  const BatchCompletionDialog({
    super.key,
    required this.batch,
    required this.onImportNext,
  });

  static Future<void> show(
    BuildContext context, {
    required BatchModel batch,
    required VoidCallback onImportNext,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BatchCompletionDialog(batch: batch, onImportNext: onImportNext),
    );
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days يوم');
    if (hours > 0) parts.add('$hours ساعة');
    if (days == 0 && hours == 0) parts.add('$minutes دقيقة');
    return parts.join(' و ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final completedAt = batch.completedAt ?? DateTime.now();
    final duration = completedAt.difference(batch.createdAt);

    return AlertDialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:  Row(
        children: [
          Icon(Icons.celebration, color: theme.primaryColor),
          const SizedBox(width: 10),
          const Text('تم بيع الدفعة بالكامل! 🎉'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الملف: ${batch.fileName}',
              style: TextStyle(color: onSurface.withOpacity(0.7))),
          const SizedBox(height: 6),
          Text('إجمالي البطاقات: ${batch.totalVouchers}',
              style: TextStyle(color: onSurface.withOpacity(0.7))),
          const SizedBox(height: 6),
          Text(
            'تم بيع الدفعة بالكامل خلال ${_formatDuration(duration)}',
            style: TextStyle(
                color: onSurface, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onImportNext();
          },
          icon: const Icon(Icons.add),
          label: const Text('استيراد ملف PDF جديد'),
        ),
      ],
    );
  }
}
