import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/colors/app_colors.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/voucher_model.dart';
import '../providers/voucher_notifier.dart';
import '../providers/repository_providers.dart';

/// Provider داخلي لجلب بطاقة المعاينة بناءً على الموضع المختار.
final _previewVoucherProvider =
    FutureProvider.family<Voucher?, ({String batchId, int position})>(
        (ref, args) async {
  final repo = ref.watch(voucherRepositoryProvider);
  return repo.getVoucherAtPosition(
    batchId: args.batchId,
    position: args.position,
  );
});

class SyncOffsetScreen extends ConsumerStatefulWidget {
  final BatchModel batch;
  const SyncOffsetScreen({super.key, required this.batch});

  static Future<bool> push(BuildContext context, BatchModel batch) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SyncOffsetScreen(batch: batch)),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SyncOffsetScreen> createState() => _SyncOffsetScreenState();
}

class _SyncOffsetScreenState extends ConsumerState<SyncOffsetScreen> {
  late double _selectedOffset;
  bool _isApplying = false;

  BatchModel get _batch => widget.batch;
  int get _totalVouchers => _batch.totalVouchers;
  int get _selectedInt => _selectedOffset.round();

  @override
  void initState() {
    super.initState();
    final firstAvailable = (_batch.soldVouchers + 1).clamp(1, _totalVouchers);
    _selectedOffset = firstAvailable.toDouble();
  }

  void _increment() {
    if (_selectedInt < _totalVouchers)
      setState(() => _selectedOffset = (_selectedInt + 1).toDouble());
  }

  void _decrement() {
    if (_selectedInt > 1)
      setState(() => _selectedOffset = (_selectedInt - 1).toDouble());
  }

  Future<void> _applySync() async {
    final offsetIndex = _selectedInt;
    if (offsetIndex <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الكرت رقم 1 هو نقطة البداية — لا يوجد شيء لتخطيه.')),
      );
      return;
    }
    final confirmed = await _showConfirmDialog(offsetIndex);
    if (!confirmed || !mounted) return;

    setState(() => _isApplying = true);
    final notifier = ref.read(voucherNotifierProvider.notifier);
    final updated =
        await notifier.syncOffset(batchId: _batch.id, offsetIndex: offsetIndex);
    if (!mounted) return;
    setState(() => _isApplying = false);

    if (updated >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated == 0
              ? 'المؤشر مُحدَّث — لا توجد بطاقات جديدة لتخطيها.'
              : 'تم تخطي $updated بطاقة ومزامنة المؤشر على الكرت #$offsetIndex.'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _showConfirmDialog(int offsetIndex) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.sync_alt, color: AppColors.mainColor),
          SizedBox(width: 8),
          Expanded(child: Text('تأكيد مزامنة المؤشر')),
        ]),
        content: Text(
          'سيتم تعليم ${offsetIndex - 1} بطاقة (من 1 حتى ${offsetIndex - 1}) كـ "مباعة".\n\nالبيع الفعلي سيبدأ من الكرت رقم #$offsetIndex.\n\n⚠️ لا يمكن التراجع عن هذه العملية.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تطبيق المزامنة'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkSurface : theme.cardTheme.color ?? Colors.white;

    final previewAsync = ref.watch(
      _previewVoucherProvider((batchId: _batch.id, position: _selectedInt)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('مزامنة مؤشر البيع'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BatchInfoCard(batch: _batch, cardColor: cardColor),
              const SizedBox(height: 24),
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              color: AppColors.mainColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('اختر نقطة بداية البيع',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('البطاقات قبل هذا الرقم ستُعلَّم كمباعة',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.mainColor.withOpacity(0.15),
                            AppColors.mainColor.withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.mainColor.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.my_location_rounded,
                                color: AppColors.mainColor, size: 22),
                            const SizedBox(width: 10),
                            Text('الكرت المستهدف: ',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7))),
                            Text('#$_selectedInt',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.mainColor,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.mainColor,
                          inactiveTrackColor:
                              AppColors.mainColor.withOpacity(0.2),
                          thumbColor: AppColors.mainColor,
                          overlayColor: AppColors.mainColor.withOpacity(0.15),
                          valueIndicatorColor: AppColors.mainColor,
                          valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 14),
                        ),
                        child: Slider(
                          min: 1.0,
                          max: _totalVouchers.toDouble(),
                          divisions:
                              _totalVouchers > 1 ? _totalVouchers - 1 : null,
                          value: _selectedOffset,
                          label: '#$_selectedInt',
                          onChanged: _totalVouchers > 1
                              ? (val) => setState(() => _selectedOffset = val)
                              : null,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FineAdjustButton(
                              icon: Icons.remove_circle_outline,
                              label: '-1',
                              onPressed: _selectedInt > 1 ? _decrement : null),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(children: [
                              Text(
                                _selectedInt == 1
                                    ? 'لا يوجد تخطٍّ'
                                    : 'تخطي ${_selectedInt - 1} بطاقة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedInt == 1
                                        ? Colors.grey
                                        : AppColors.mainColor),
                              ),
                              Text('${_batch.totalVouchers} بطاقة إجمالاً',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ]),
                          ),
                          const SizedBox(width: 16),
                          _FineAdjustButton(
                              icon: Icons.add_circle_outline,
                              label: '+1',
                              onPressed: _selectedInt < _totalVouchers
                                  ? _increment
                                  : null),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45))),
                          Text('$_totalVouchers',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _PreviewCard(
                  previewAsync: previewAsync,
                  position: _selectedInt,
                  cardColor: cardColor),
              const SizedBox(height: 28),
              AnimatedOpacity(
                opacity: _isApplying ? 0.6 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedInt > 1
                        ? AppColors.mainColor
                        : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isApplying ? null : _applySync,
                  icon: _isApplying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(
                          Icons.sync_alt_rounded,
                          size: 22.sp,
                          color: AppColors.darkPrimaryText,
                        ),
                  label: Text(
                    _isApplying
                        ? 'جارٍ تطبيق المزامنة...'
                        : 'تطبيق الانتقال والمزامنة',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.darkPrimaryText),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedInt > 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم تعليم ${_selectedInt - 1} بطاقة كمباعة. لا يمكن التراجع عن هذا الإجراء.',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ]),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'حرّك المؤشر لتحديد رقم البطاقة التي ستبدأ منها.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.blue))),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FineAdjustButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _FineAdjustButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Icon(icon,
                size: 32,
                color: enabled ? AppColors.mainColor : Colors.grey.shade400),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        enabled ? AppColors.mainColor : Colors.grey.shade400)),
          ]),
        ),
      ),
    );
  }
}

class _BatchInfoCard extends StatelessWidget {
  final BatchModel batch;
  final Color cardColor;
  const _BatchInfoCard({required this.batch, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.folder_open_rounded,
                  color: AppColors.mainColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.fileName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    Text('مباع: ${batch.soldVouchers} / ${batch.totalVouchers}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6))),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: batch.progress,
              minHeight: 6,
              backgroundColor: AppColors.mainColor.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.mainColor),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final AsyncValue<Voucher?> previewAsync;
  final int position;
  final Color cardColor;
  const _PreviewCard(
      {required this.previewAsync,
      required this.position,
      required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side:
            BorderSide(color: AppColors.mainColor.withOpacity(0.3), width: 1.5),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.preview_rounded,
                color: AppColors.mainColor, size: 20),
            const SizedBox(width: 8),
            Text('معاينة البطاقة #$position',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 20),
          previewAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('خطأ: $e',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            data: (voucher) {
              if (voucher == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('لا توجد بطاقة في هذا الموضع.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VoucherField(
                        label: 'اسم المستخدم',
                        value: voucher.username,
                        icon: Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _VoucherField(
                        label: 'كلمة المرور',
                        value: voucher.password,
                        icon: Icons.lock_outline_rounded),
                    const SizedBox(height: 12),
                    _StatusChip(status: voucher.status),
                  ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VoucherStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case VoucherStatus.available:
        return Colors.green;
      case VoucherStatus.sold:
        return Colors.orange;
      case VoucherStatus.voided:
        return Colors.red;
    }
  }

  IconData get _icon {
    switch (status) {
      case VoucherStatus.available:
        return Icons.check_circle_outline;
      case VoucherStatus.sold:
        return Icons.sell_outlined;
      case VoucherStatus.voided:
        return Icons.cancel_outlined;
    }
  }

  String get _label {
    switch (status) {
      case VoucherStatus.available:
        return 'متاحة';
      case VoucherStatus.sold:
        return 'مباعة';
      case VoucherStatus.voided:
        return 'ملغاة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: 14, color: _color),
        const SizedBox(width: 6),
        Text(_label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: _color)),
      ]),
    );
  }
}

class _VoucherField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _VoucherField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.mainColor),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5))),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ]),
    ]);
  }
}
