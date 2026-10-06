import 'package:flutter/material.dart';

import '../../data/models/voucher_format.dart';

/// Lets the user pick or customize the digit-length pattern before
/// importing a PDF, since different batches use different formats
/// (e.g. 7-digit/2-3-digit "classic" vs 6-digit/1-digit "compact").
class ImportFormatDialog extends StatefulWidget {
  const ImportFormatDialog({super.key});

  static Future<VoucherFormat?> show(BuildContext context) {
    return showDialog<VoucherFormat>(
      context: context,
      builder: (_) => const ImportFormatDialog(),
    );
  }

  @override
  State<ImportFormatDialog> createState() => _ImportFormatDialogState();
}

class _ImportFormatDialogState extends State<ImportFormatDialog> {
  final _userLenCtrl = TextEditingController(text: '7');
  final _passMinCtrl = TextEditingController(text: '2');
  final _passMaxCtrl = TextEditingController(text: '3');

  @override
  void dispose() {
    _userLenCtrl.dispose();
    _passMinCtrl.dispose();
    _passMaxCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(VoucherFormat format) {
    setState(() {
      _userLenCtrl.text = '${format.usernameLength}';
      _passMinCtrl.text = '${format.passwordMinLength}';
      _passMaxCtrl.text = '${format.passwordMaxLength}';
    });
  }

  void _confirm() {
    final userLen = int.tryParse(_userLenCtrl.text.trim());
    final passMin = int.tryParse(_passMinCtrl.text.trim());
    final passMax = int.tryParse(_passMaxCtrl.text.trim());

    if (userLen == null || passMin == null || passMax == null || passMin > passMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال أرقام صحيحة ومنطقية')),
      );
      return;
    }

    Navigator.of(context).pop(VoucherFormat(
      usernameLength: userLen,
      passwordMinLength: passMin,
      passwordMaxLength: passMax,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('صيغة أرقام هذه الدفعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(VoucherFormat.classic),
                  child: const Text('نمط 7/2-3 (كلاسيكي)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(VoucherFormat.compact),
                  child: const Text('نمط 6/1 (مختصر)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userLenCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد خانات اليوزر'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _passMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'أقل عدد خانات للباسورد'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _passMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'أعلى عدد خانات للباسورد'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _confirm, child: const Text('استيراد')),
      ],
    );
  }
}
