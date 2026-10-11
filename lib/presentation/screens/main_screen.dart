import 'dart:io';
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
import '../widgets/batch_list_item.dart';
import '../widgets/custom_quantity_dialog.dart';
import '../widgets/import_format_dialog.dart';
import '../widgets/qr_code_dialog.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/stock_indicator.dart';
import '../widgets/voucher_display_panel.dart';
import 'sync_offset_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _dialogShownForCompletedBatch = false;

  /// يفتح أولاً حوار تخصيص الدفعة، ثم يفتح نافذة اختيار الملف.
  Future<void> _importPdf(
      BuildContext context, VoucherNotifier notifier) async {
    final format = await ImportFormatDialog.show(context);
    if (format == null) return; // المستخدم ألغى
    if (!context.mounted) return;
    await notifier.pickAndImportPdf(format: format);
  }

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
            onImportNext: () => _importPdf(context, notifier),
          );
        });
      } else if (!next.isBatchSoldOut) {
        _dialogShownForCompletedBatch = false;
      }
    });

    final isDesktop =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدير بطاقات الفاوتشر'),
        actions: [
          if (state.hasActiveBatch)
            IconButton(
              tooltip: 'مزامنة مؤشر البيع',
              icon: const Icon(Icons.sync),
              onPressed: () async {
                final synced = await SyncOffsetScreen.push(context, state.activeBatch!);
                if (synced) await notifier.refresh();
              },
            ),
          IconButton(
            tooltip: 'استيراد ملف PDF',
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importPdf(context, notifier),
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
          ),
          if (isDesktop)
            IconButton(
              tooltip: 'الوضع العائم المدمج',
              icon: const Icon(Icons.picture_in_picture_alt),
              onPressed: () => _enterCompactMode(context),
            ),
        ],
      ),
      body: SafeArea(
        child: state.status == VoucherStatusFlag.loading &&
                !state.hasActiveBatch
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: notifier.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DailySummaryCard(state: state),
                      const SizedBox(height: 16),
                      if (!state.hasActiveBatch)
                        _NoActiveBatchCard(
                            onImport: () => _importPdf(context, notifier))
                      else
                        _ActiveBatchSection(state: state, notifier: notifier),
                      const SizedBox(height: 16),
                      _BatchHistorySection(state: state, notifier: notifier),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: state.hasActiveBatch
          ? SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonWidget(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ButtonWidget(
                            color: AppColors.mainColor,
                            shadow: AppColors.mainColor,
                            name: 'تم ✅ (تم الإرسال)',
                            icons: Icons.check_circle,
                            textColor: Colors.white,
                            onPress: state.lastDispensed.isNotEmpty
                                ? notifier.confirmSent
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ButtonWidget(
                            color: AppColors.grayDark,
                            shadow: AppColors.grayDark,
                            name: 'إلغاء العملية',
                            icons: Icons.keyboard_return_outlined,
                            textColor: Colors.white,
                            onPress: state.canUndo
                                ? notifier.undoLastTransaction
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _enterCompactMode(BuildContext context) async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      ref.read(isCompactModeProvider.notifier).state = true;
      await windowManager.setSize(
        const Size(
            AppConstants.compactWindowWidth, AppConstants.compactWindowHeight),
      );
      await windowManager.setAlwaysOnTop(true);
    }
  }
}

class _DailySummaryCard extends StatelessWidget {
  final VoucherState state;
  const _DailySummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.dailySummary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _StatCard(
          label: 'مبيعات اليوم',
          value: '${summary?.soldToday ?? 0}',
          icon: Icons.trending_up,
          color: AppColors.mainColor,
        ),
        _StatCard(
          label: 'المخزون النشط',
          value: '${summary?.currentActiveStock ?? 0}',
          icon: Icons.inventory_2_outlined,
          color: AppColors.colodBlue,
        ),
        _StatCard(
          label: 'الدفعات المكتملة',
          value: '${summary?.batchesCompletedTotal ?? 0}',
          icon: Icons.task_alt,
          color: Colors.green,
        ),
        _StatCard(
          label: 'إجمالي الدفعات',
          value: '${summary?.totalBatches ?? 0}',
          icon: Icons.folder_outlined,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0.5,
      color: isDark ? AppColors.darkSurface : theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withOpacity(0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.darkSurface : theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            StockIndicator(
                total: batch.totalVouchers, sold: batch.soldVouchers),
            const SizedBox(height: 16),
            QuickActionChips(
              maxAvailable: state.availableCount,
              onSelect: (n) => notifier.dispense(n),
              onCustom: () async {
                final qty = await CustomQuantityDialog.show(context,
                    maxAvailable: state.availableCount);
                if (qty != null) await notifier.dispense(qty);
              },
            ),
            const SizedBox(height: 14),
            VoucherDisplayPanel(vouchers: state.lastDispensed),
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
              BatchListItem(batch: batch, notifier: notifier),
          ],
        ),
      ),
    );
  }
}
