import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/voucher_model.dart';

/// Builds a compact, all-Latin SMS payload for a list of dispensed vouchers.
///
/// Format examples:
///   • 1 voucher  → `U:887943 P:5`                                  (13 chars)
///   • 3 vouchers → `1)U:887943 P:5 2)U:884171 P:7 3)U:123456 P:9`
///
/// Using only ASCII keeps the SMS in GSM 7-bit mode, raising the per-message
/// limit from 70 (Unicode/Arabic) to 160 characters – halving cost.
String buildCompactSmsText(List<Voucher> vouchers) {
  if (vouchers.isEmpty) return '';
  if (vouchers.length == 1) {
    final v = vouchers.first;
    return 'U:${v.username} P:${v.password}';
  }
  return vouchers
      .asMap()
      .entries
      .map((e) => '${e.key + 1})U:${e.value.username} P:${e.value.password}')
      .join(' ');
}

/// Computes SMS segment statistics for [text].
///
/// GSM 7-bit (pure ASCII/Latin): 160 chars/SMS, 153 when multipart.
/// Unicode (contains Arabic etc.): 70 chars/SMS, 67 when multipart.
({int charCount, int smsCount, int limit, bool isUnicode}) smsStats(
    String text) {
  // A conservative GSM-7 check: if all chars are basic ASCII printable, treat
  // as GSM-7. The compact formatter always produces ASCII, so this will always
  // hit the 160-char branch for our use-case.
  final isUnicode = text.runes.any((r) => r > 127);
  final singleLimit = isUnicode ? 70 : 160;
  final multiLimit = isUnicode ? 67 : 153;
  final len = text.length;

  final smsCount = len <= singleLimit ? 1 : (len / multiLimit).ceil();

  return (
    charCount: len,
    smsCount: smsCount,
    limit: singleLimit,
    isUnicode: isUnicode,
  );
}

/// Modal dialog that renders a QR code from a compact, SMS-optimised payload
/// derived from [vouchers]. Shows a character / SMS counter below the QR so
/// the operator can verify cost before scanning.
class QrCodeDialog extends StatelessWidget {
  final List<Voucher> vouchers;

  const QrCodeDialog({super.key, required this.vouchers});

  /// Convenience launcher – call from any [BuildContext].
  static Future<void> show(BuildContext context,
      {required List<Voucher> vouchers}) {
    return showDialog(
      context: context,
      builder: (_) => QrCodeDialog(vouchers: vouchers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactText = buildCompactSmsText(vouchers);
    final stats = smsStats(compactText);

    // Counter badge color: green = 1 SMS, amber = 2, red = 3+
    final Color counterColor;
    if (stats.smsCount == 1) {
      counterColor = Colors.green.shade600;
    } else if (stats.smsCount == 2) {
      counterColor = Colors.amber.shade700;
    } else {
      counterColor = theme.colorScheme.error;
    }

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        children: [
          Icon(Icons.qr_code_2_rounded,
              color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'مسح الكروت (مُجهَّز للـ SMS)',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // X close button in title bar
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── QR Code ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: compactText.isEmpty
                  ? const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: Text('لا توجد بيانات')),
                    )
                  : QrImageView(
                      data: compactText,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
            ),

            const SizedBox(height: 14),

            // ── Compact payload preview (selectable / copyable) ───────────
            if (compactText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.4)),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    compactText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── SMS counter badge ─────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: counterColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: counterColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sms_outlined, size: 14, color: counterColor),
                    const SizedBox(width: 5),
                    Text(
                      '${stats.charCount}/${stats.limit} chars'
                      ' — ${stats.smsCount} SMS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: counterColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Multi-part warning
              if (stats.smsCount > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ سيُرسَل كـ ${stats.smsCount} رسائل (تكلفة مضاعفة)',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: counterColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
