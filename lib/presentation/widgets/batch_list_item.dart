import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/utils/button_widget.dart';
import '../../core/utils/colors/app_colors.dart';
import '../../data/models/batch_model.dart';
import '../providers/voucher_notifier.dart';

class BatchListItem extends StatelessWidget {
  final BatchModel batch;
  final VoucherNotifier notifier;

  const BatchListItem({
    super.key,
    required this.batch,
    required this.notifier,
  });

  String _formatSaleDuration(DateTime createdAt, DateTime? completedAt) {
    final end = completedAt ?? DateTime.now();
    final diff = end.difference(createdAt);
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    return 'مدة البيع: $days أيام و $hours ساعات';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        batch.isCurrentActive
            ? Icons.play_circle_fill
            : Icons.circle_outlined,
        color: batch.isCurrentActive ? onSurface : Colors.white38,
      ),
      title: Text(batch.fileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${batch.soldVouchers} / ${batch.totalVouchers} مباع'),
          if (batch.isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatSaleDuration(batch.createdAt, batch.completedAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!batch.isCurrentActive)
            TextButton(
              onPressed: () => notifier.switchActiveBatch(batch.id),
              child: const Text('تفعيل'),
            ),
          // تم تعطيل وحذف زر إعادة التفعيل نهائياً
          // إخفاء زر الحذف على Android وإبقاؤه على macOS فقط
          if (Platform.isMacOS)
            IconButton(
              tooltip: 'حذف الدفعة',
              icon: Icon(Icons.delete_sharp, color: AppColors.aleart),
              onPressed: () async {
                final confirmed = await _confirm(
                  context,
                  title: 'حذف الدفعة نهائياً؟',
                  content:
                      'سيتم حذف "${batch.fileName}" وجميع بطاقاتها (${batch.totalVouchers} بطاقة) نهائياً. لا يمكن التراجع عن هذا الإجراء.',
                  confirmLabel: 'حذف',
                  confirmColor: AppColors.aleart,
                );
                if (confirmed) await notifier.deleteBatch(batch.id);
              },
            ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ButtonWidget(
                  name: confirmLabel,
                  onPress: () => Navigator.of(context).pop(true),
                  color: AppColors.mainColor,
                  textColor: Colors.white,
                  shadow: AppColors.mainColor,
                ),
              ),
              Expanded(
                child: ButtonWidget(
                  name: 'إلغاء',
                  onPress: () => Navigator.of(context).pop(false),
                  color: AppColors.aleart,
                  textColor: Colors.white,
                  shadow: AppColors.aleart,
                ),
              ),
            ],
          )
        ],
      ),
    );
    return result ?? false;
  }
}
