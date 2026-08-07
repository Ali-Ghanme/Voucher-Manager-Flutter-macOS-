import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voucher_manager/core/utils/button_widget.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/colors/app_colors.dart';
import '../providers/repository_providers.dart';
import '../providers/voucher_notifier.dart';
import '../providers/voucher_state.dart';
import '../widgets/batch_completion_dialog.dart';
import '../widgets/custom_quantity_dialog.dart';
import '../widgets/qr_code_dialog.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/stock_indicator.dart';
import '../widgets/voucher_display_panel.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _dialogShownForCompletedBatch = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voucherNotifierProvider);
    final notifier = ref.read(voucherNotifierProvider.notifier);

    ref.listen<VoucherState>(voucherNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      if (next.isBatchSoldOut && !_dialogShownForCompletedBatch) {
        _dialogShownForCompletedBatch = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          BatchCompletionDialog.show(
            context,
            batch: next.activeBatch!,
            onImportNext: () => notifier.pickAndImportPdf(),
          );
        });
      } else if (!next.isBatchSoldOut) {
        _dialogShownForCompletedBatch = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدير بطاقات الفاوتشر'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
          ),
          IconButton(
            tooltip: 'الوضع العائم المدمج',
            icon: const Icon(Icons.picture_in_picture_alt),
            onPressed: () => _enterCompactMode(context),
          ),
        ],
      ),
      body: state.status == VoucherStatusFlag.loading && !state.hasActiveBatch
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DailySummaryCard(state: state),
                    const SizedBox(height: 20),
                    if (!state.hasActiveBatch)
                      _NoActiveBatchCard(onImport: notifier.pickAndImportPdf)
                    else
                      _ActiveBatchSection(state: state, notifier: notifier),
                    const SizedBox(height: 20),
                    _BatchHistorySection(state: state, notifier: notifier),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _enterCompactMode(BuildContext context) async {
    ref.read(isCompactModeProvider.notifier).state = true;
    await windowManager.setSize(
      const Size(
          AppConstants.compactWindowWidth, AppConstants.compactWindowHeight),
    );
    await windowManager.setAlwaysOnTop(true);
  }
}

class _DailySummaryCard extends StatelessWidget {
  final VoucherState state;
  const _DailySummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.dailySummary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _StatBlock(
                label: 'مبيعات اليوم', value: '${summary?.soldToday ?? 0}'),
            _StatBlock(
                label: 'الدفعات المكتملة',
                value: '${summary?.batchesCompletedTotal ?? 0}'),
            _StatBlock(
                label: 'المخزون النشط',
                value: '${summary?.currentActiveStock ?? 0}'),
            _StatBlock(
                label: 'إجمالي الدفعات',
                value: '${summary?.totalBatches ?? 0}'),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _NoActiveBatchCard extends StatelessWidget {
  final VoidCallback onImport;
  const _NoActiveBatchCard({required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: onSurface.withOpacity(0.38)),
            const SizedBox(height: 16),
            Text('لا توجد دفعة نشطة حالياً',
                style:
                    TextStyle(fontSize: 16, color: onSurface.withOpacity(0.7))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('استيراد ملف PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBatchSection extends StatelessWidget {
  final VoucherState state;
  final VoucherNotifier notifier;
  const _ActiveBatchSection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final batch = state.activeBatch!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.fileName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('#${batch.id}',
                    style: TextStyle(
                        color: onSurface.withOpacity(0.38), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            StockIndicator(
                total: batch.totalVouchers, sold: batch.soldVouchers),
            const SizedBox(height: 20),
            VoucherDisplayPanel(vouchers: state.lastDispensed),
            const SizedBox(height: 12),
            // ── QR Code button ─────────────────────────────────
            Tooltip(
              message: 'عرض QR Code لمسح الكروت وإرسالها عبر SMS',
              child: ButtonWidget(
                color: state.lastDispensed.isNotEmpty
                    ? AppColors.mainColor
                    : AppColors.grayDark,
                shadow: state.lastDispensed.isNotEmpty
                    ? AppColors.mainColor
                    : AppColors.grayDark,
                name: 'عرض QR Code للإرسال عبر SMS',
                icons: Icons.qr_code_2_rounded,
                textColor: Colors.white,
                onPress: state.lastDispensed.isNotEmpty
                    ? () => QrCodeDialog.show(
                          context,
                          vouchers: state.lastDispensed,
                        )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            QuickActionChips(
              maxAvailable: state.availableCount,
              onSelect: (n) => notifier.dispense(n),
              onCustom: () async {
                final qty = await CustomQuantityDialog.show(context,
                    maxAvailable: state.availableCount);
                if (qty != null) await notifier.dispense(qty);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    color: AppColors.grayDark,
                    shadow: AppColors.grayDark,
                    name: 'إلغاء العملية السابقة',
                    icons: Icons.keyboard_return_outlined,
                    textColor: Colors.white,
                    onPress:
                        state.canUndo ? notifier.undoLastTransaction : null,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ButtonWidget(
                color: AppColors.mainColor, // أو أي لون أخضر عندك يدل على "تم"
                shadow: AppColors.mainColor,
                name: 'تم ✅ (تم الإرسال)',
                icons: Icons.check_circle,
                textColor: Colors.white,
                onPress: state.lastDispensed.isNotEmpty
                    ? notifier.confirmSent
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchHistorySection extends StatelessWidget {
  final VoucherState state;
  final VoucherNotifier notifier;
  const _BatchHistorySection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.allBatches.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('سجل الدفعات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            for (final batch in state.allBatches)
              ListTile(
                leading: Icon(
                  batch.isCurrentActive
                      ? Icons.play_circle_fill
                      : Icons.circle_outlined,
                  color: batch.isCurrentActive ? onSurface : Colors.white38,
                ),
                title: Text(batch.fileName),
                subtitle:
                    Text('${batch.soldVouchers} / ${batch.totalVouchers} مباع'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!batch.isCurrentActive)
                      TextButton(
                        onPressed: () => notifier.switchActiveBatch(batch.id),
                        child: const Text('تفعيل'),
                      ),
                    IconButton(
                      tooltip: 'إعادة ضبط الدفعة',
                      icon: const Icon(Icons.restart_alt_outlined,
                          color: AppColors.mainColor),
                      onPressed: () async {
                        final confirmed = await _confirm(
                          context,
                          title: 'إعادة ضبط الدفعة؟',
                          content:
                              'ستعود جميع بطاقات "${batch.fileName}" (${batch.totalVouchers} بطاقة) إلى حالة "متاح"، وسيتم تصفير عدد المبيعات. لا يمكن التراجع عن هذا الإجراء.',
                          confirmLabel: 'إعادة ضبط',
                          confirmColor: AppColors.warning,
                        );
                        if (confirmed) await notifier.resetBatch(batch.id);
                      },
                    ),
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
              ),
          ],
        ),
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
