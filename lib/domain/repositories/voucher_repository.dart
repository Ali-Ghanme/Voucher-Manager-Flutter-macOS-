import 'dart:io';

import '../../data/models/batch_model.dart';
import '../../data/models/voucher_format.dart';
import '../../data/models/voucher_model.dart';

/// Contract for all voucher/batch persistence and business operations.
/// The presentation layer (BLoC/Notifiers) depends only on this
/// abstraction, never on the concrete SQLite implementation - this
/// keeps the door open to swapping storage engines (e.g. Isar) later.
abstract class VoucherRepository {
  // ---------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------

  /// Parses [pdfFile], creates a new [Batch], persists all extracted
  /// vouchers atomically, and marks the new batch as active
  /// (deactivating any previously active batch). Returns the created
  /// Batch.
  Future<BatchModel> importPdfBatch(File pdfFile,
      {required VoucherFormat format});

  // ---------------------------------------------------------------------
  // Batches
  // ---------------------------------------------------------------------

  Future<BatchModel?> getActiveBatch();
  Future<List<BatchModel>> getAllBatches();
  Future<void> setActiveBatch(String batchId);

  // ---------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------
  /// Permanently deletes [batchId] and all its vouchers. If it was the
  /// active batch, no batch remains active afterwards.
  Future<void> deleteBatch(String batchId);

  /// Resets [batchId] back to a fresh state: every voucher (SOLD or
  /// VOID) becomes AVAILABLE again, soldVouchers resets to 0, and
  /// completedAt is cleared.
  Future<void> resetBatch(String batchId);

  // ---------------------------------------------------------------------
  // Dispense / Undo / Void
  // ---------------------------------------------------------------------

  /// Atomically marks [count] AVAILABLE vouchers from the active batch
  /// as SOLD, tagged with a fresh transactionId, and returns the sold
  /// vouchers plus the ready-to-copy clipboard message.
  ///
  /// Throws [InsufficientStockException] if fewer than [count] vouchers
  /// are available. Throws [NoActiveBatchException] if there is no
  /// active batch.
  Future<DispenseResult> dispenseVouchers(int count);

  /// Reverts the most recent dispense transaction (if still within the
  /// undo window) - sets those vouchers back to AVAILABLE and
  /// decrements the batch's soldVouchers counter.
  Future<void> undoLastTransaction();

  /// Marks a single voucher as VOID (e.g. physically damaged card).
  Future<void> voidVoucher(int voucherId);

  // ---------------------------------------------------------------------
  // Sync Offset (مزامنة مؤشر بداية البيع)
  // ---------------------------------------------------------------------

  /// يُحوّل كل البطاقات من الرقم 1 حتى [offsetIndex] (حصراً) إلى حالة SOLD،
  /// مما يُزامن مؤشر البيع مع جهاز آخر. يُعيد عدد البطاقات التي تم تعديلها.
  ///
  /// [offsetIndex]: الرقم الترتيبي للبطاقة التي يجب أن تكون التالية للبيع
  /// (أي البطاقات 1..offsetIndex-1 ستُعلَّم SOLD).
  Future<int> syncOffset({
    required String batchId,
    required int offsetIndex,
  });

  /// يُعيد بيانات البطاقة عند الموضع [position] (1-based) في الدفعة.
  /// يُستخدم لعرض بطاقة المعاينة أثناء السحب على الـ Slider.
  Future<Voucher?> getVoucherAtPosition({
    required String batchId,
    required int position,
  });

  // ---------------------------------------------------------------------
  // Stock / Analytics
  // ---------------------------------------------------------------------

  Future<int> getAvailableCount(String batchId);
  Future<List<Voucher>> getVouchersByStatus(
      String batchId, VoucherStatus status);
  Future<DailySummary> getDailySummary();
}

/// Result of a successful dispense operation - carries everything the
/// UI needs to render the compact panel and populate the clipboard.
class DispenseResult {
  final List<Voucher> vouchers;
  final String clipboardMessage;
  final String transactionId;

  const DispenseResult({
    required this.vouchers,
    required this.clipboardMessage,
    required this.transactionId,
  });
}

/// Aggregated stats for the Daily Summary Dashboard.
class DailySummary {
  final int soldToday;
  final int batchesCompletedTotal;
  final int currentActiveStock;
  final int totalBatches;

  const DailySummary({
    required this.soldToday,
    required this.batchesCompletedTotal,
    required this.currentActiveStock,
    required this.totalBatches,
  });
}
