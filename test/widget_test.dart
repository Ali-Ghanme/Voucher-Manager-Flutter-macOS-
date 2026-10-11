import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_manager/data/models/batch_model.dart';

void main() {
  test('BatchModel isCompleted and progress calculation', () {
    final batch = BatchModel(
      id: 'batch-1',
      fileName: 'test.pdf',
      totalVouchers: 10,
      soldVouchers: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      completedAt: DateTime.now(),
    );

    expect(batch.isSoldOut, isTrue);
    expect(batch.isCompleted, isTrue);
    expect(batch.remainingVouchers, 0);

    final diff = batch.completedAt!.difference(batch.createdAt);
    expect(diff.inDays, 2);
    expect(diff.inHours.remainder(24), 5);
  });
}
