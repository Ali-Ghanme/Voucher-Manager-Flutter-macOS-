import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Small dialog for entering an arbitrary dispense quantity, used by
/// the "مخصص" (custom) quick-action chip.
class CustomQuantityDialog extends StatefulWidget {
  final int maxAvailable;

  const CustomQuantityDialog({super.key, required this.maxAvailable});

  static Future<int?> show(BuildContext context, {required int maxAvailable}) {
    return showDialog<int>(
      context: context,
      builder: (_) => CustomQuantityDialog(maxAvailable: maxAvailable),
    );
  }

  @override
  State<CustomQuantityDialog> createState() => _CustomQuantityDialogState();
}

class _CustomQuantityDialogState extends State<CustomQuantityDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'الرجاء إدخال رقم صحيح أكبر من صفر');
      return;
    }
    if (value > widget.maxAvailable) {
      setState(() => _error = 'الحد الأقصى المتاح هو ${widget.maxAvailable}');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor:
          theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('عدد مخصص من البطاقات'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'مثال: 15 (المتاح: ${widget.maxAvailable})',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(''),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
