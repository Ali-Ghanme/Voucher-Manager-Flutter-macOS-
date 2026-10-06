import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voucher_manager/core/utils/colors/app_colors.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/button_widget.dart';
import '../providers/repository_providers.dart';
import '../providers/voucher_notifier.dart';
import '../providers/voucher_state.dart';
import '../widgets/custom_quantity_dialog.dart';
import '../widgets/import_format_dialog.dart';
import '../widgets/qr_code_dialog.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/stock_indicator.dart';
import '../widgets/voucher_display_panel.dart';

/// Compact, always-on-top window (380x520 by default) meant to sit in
/// a corner of the screen while the operator works from their phone -
/// large bold text, minimal chrome, everything reachable in one click.
class CompactFloatingScreen extends ConsumerWidget {
  const CompactFloatingScreen({super.key});

  Future<void> _exitCompactMode(WidgetRef ref) async {
    ref.read(isCompactModeProvider.notifier).state = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(
      const Size(
          AppConstants.normalWindowWidth, AppConstants.normalWindowHeight),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voucherNotifierProvider);
    final notifier = ref.read(voucherNotifierProvider.notifier);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    ref.listen<VoucherState>(voucherNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(next.errorMessage!, style: const TextStyle(fontSize: 13)),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Draggable custom "title bar" -------------------------
            GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(
                height: 36,
                color: onSurface.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator,
                        size: 16, color: onSurface.withOpacity(0.38)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الوضع العائم',
                        style: TextStyle(
                            fontSize: 12, color: onSurface.withOpacity(0.54)),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      icon: Icon(Icons.close_fullscreen,
                          color: onSurface.withOpacity(0.54)),
                      tooltip: 'الخروج من الوضع العائم',
                      onPressed: () => _exitCompactMode(ref),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: state.hasActiveBatch
                  ? _CompactBody(state: state, notifier: notifier)
                  : _CompactEmptyState(notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  final VoucherNotifier notifier;
  const _CompactEmptyState({required this.notifier});

  Future<void> _importPdf(BuildContext context) async {
    final format = await ImportFormatDialog.show(context);
    if (format == null) return;
    if (!context.mounted) return;
    await notifier.pickAndImportPdf(format: format);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 40, color: onSurface.withOpacity(0.38)),
            const SizedBox(height: 12),
            Text('لا توجد دفعة نشطة',
                style: TextStyle(color: onSurface.withOpacity(0.7))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _importPdf(context),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('استيراد PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  final VoucherState state;
  final VoucherNotifier notifier;
  const _CompactBody({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final batch = state.activeBatch!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockIndicator(total: batch.totalVouchers, sold: batch.soldVouchers),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: VoucherDisplayPanel(vouchers: state.lastDispensed),
            ),
          ),
          const SizedBox(height: 12),
          QuickActionChips(
            maxAvailable: state.availableCount,
            onSelect: (n) => notifier.dispense(n),
            onCustom: () async {
              final qty = await CustomQuantityDialog.show(context,
                  maxAvailable: state.availableCount);
              if (qty != null) await notifier.dispense(qty);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // ── Copy button (matches main screen ButtonWidget style) ──
              Expanded(
                child: ButtonWidget(
                  color: AppColors.warning,
                  shadow: AppColors.warning,
                  name: 'نسخ (Cmd+C)',
                  icons: Icons.copy,
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  onPress: state.lastClipboardMessage != null
                      ? () async {
                          await Clipboard.setData(
                            ClipboardData(text: state.lastClipboardMessage!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم النسخ'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),

              // ── QR Code button ────────────────────────────────
              Tooltip(
                message: 'عرض QR Code للإرسال عبر SMS',
                child: ButtonWidget(
                  color: state.lastDispensed.isNotEmpty
                      ? AppColors.mainColor
                      : AppColors.grayDark,
                  shadow: state.lastDispensed.isNotEmpty
                      ? AppColors.mainColor
                      : AppColors.grayDark,
                  icons: Icons.qr_code_2_rounded,
                  onPress: state.lastDispensed.isNotEmpty
                      ? () => QrCodeDialog.show(
                            context,
                            vouchers: state.lastDispensed,
                          )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              // زر التأكيد - يظهر البطاقات المُرسلة فقط تختفي من الشاشة
              SizedBox(
                width: double.infinity,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: ButtonWidget(
                      color: AppColors.grayDark,
                      shadow: AppColors.grayDark,
                      name:
                          'إلغاء آخر عملية بيع', // بدل "العودة للخلف" - كانت التسمية مضللة
                      icons: Icons.undo,
                      textColor: Colors.white,
                      onPress:
                          state.canUndo ? notifier.undoLastTransaction : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ButtonWidget(
                      color: AppColors.errorColor,
                      shadow: AppColors.errorColor,
                      name: 'إبطال',
                      icons: Icons.block,
                      textColor: Colors.white,
                      onPress: state.lastDispensed.isNotEmpty
                          ? () => notifier
                              .voidVoucher(state.lastDispensed.first.id!)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
