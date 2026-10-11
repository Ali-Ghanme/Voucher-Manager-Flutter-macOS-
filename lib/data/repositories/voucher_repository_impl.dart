import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../domain/repositories/voucher_repository.dart';
import '../datasources/database_helper.dart';
import '../models/batch_model.dart';
import '../models/voucher_format.dart';
import '../models/voucher_model.dart';
import '../services/pdf_parser_service.dart';

/// SQLite-backed implementation of [VoucherRepository].
///
/// Every state-mutating operation (import, dispense, undo, void) runs
/// inside a single `db.transaction()` block so that either the whole
/// operation succeeds or none of it does - this is what prevents
/// double-selling: two concurrent dispense calls cannot both grab the
/// same voucher rows, because SQLite serializes writers within a
/// transaction.
class VoucherRepositoryImpl implements VoucherRepository {
  final DatabaseHelper _dbHelper;
  final PdfParserService _pdfParser;
  final Uuid _uuid = const Uuid();

  /// In-memory pointer to the most recent dispense transaction, used to
  /// power one-click Undo. Cleared after undo, after the timeout, or
  /// when a new dispense happens.
  String? _lastTransactionId;

  VoucherRepositoryImpl({
    DatabaseHelper? dbHelper,
    PdfParserService? pdfParser,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _pdfParser = pdfParser ?? PdfParserService();

  // =====================================================================
  // IMPORT
  // =====================================================================

  @override
  Future<BatchModel> importPdfBatch(File pdfFile,
      {required VoucherFormat format}) async {
    final pairs =
        await _pdfParser.extractVouchersFromPdf(pdfFile, format: format);
    // extractVouchersFromPdf already throws EmptyPdfException /
    // RegexMismatchException for the zero-result cases, so by this
    // point `pairs` is guaranteed non-empty.

    final db = await _dbHelper.database;
    final now = DateTime.now();
    final batchId = 'Batch_${_formatBatchTimestamp(now)}';

    final newBatch = BatchModel(
      id: batchId,
      fileName: pdfFile.uri.pathSegments.isNotEmpty
          ? pdfFile.uri.pathSegments.last
          : pdfFile.path,
      totalVouchers: pairs.length,
      soldVouchers: 0,
      createdAt: now,
      isCurrentActive: true,
    );

    try {
      await db.transaction((txn) async {
        // Deactivate any currently active batch first.
        await txn.update(
          AppConstants.tableBatches,
          {'isCurrentActive': 0},
          where: 'isCurrentActive = 1',
        );

        await txn.insert(AppConstants.tableBatches, newBatch.toMap());

        final batchInsert = txn.batch();
        for (final pair in pairs) {
          final voucher = Voucher(
            batchId: batchId,
            username: pair.username,
            password: pair.password,
            status: VoucherStatus.available,
          );
          batchInsert.insert(
            AppConstants.tableVouchers,
            voucher.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore, // dedupe safety net
          );
        }
        await batchInsert.commit(noResult: true);
      });
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    return newBatch;
  }

  String _formatBatchTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}_${two(dt.month)}_${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }

  // ================================== Delete =================================
  @override
  Future<void> deleteBatch(String batchId) async {
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        await txn.delete(
          AppConstants.tableVouchers,
          where: 'batchId = ?',
          whereArgs: [batchId],
        );
        final count = await txn.delete(
          AppConstants.tableBatches,
          where: 'id = ?',
          whereArgs: [batchId],
        );
        if (count == 0) {
          throw DatabaseOperationException('Batch not found: $batchId');
        }
      });
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    // Guard against a stale in-memory Undo pointer referencing rows
    // that no longer exist.
    _lastTransactionId = null;
  }

  @override
  Future<void> resetBatch(String batchId) async {
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        final rows = await txn.query(
          AppConstants.tableBatches,
          where: 'id = ?',
          whereArgs: [batchId],
        );
        if (rows.isEmpty) {
          throw DatabaseOperationException('Batch not found: $batchId');
        }

        await txn.update(
          AppConstants.tableVouchers,
          {
            'status': AppConstants.statusAvailable,
            'soldAt': null,
            'transactionId': null,
          },
          where: 'batchId = ?',
          whereArgs: [batchId],
        );

        await txn.update(
          AppConstants.tableBatches,
          {'soldVouchers': 0, 'completedAt': null},
          where: 'id = ?',
          whereArgs: [batchId],
        );
      });
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    _lastTransactionId = null;
  }

  // =====================================================================
  // BATCHES
  // =====================================================================

  @override
  Future<BatchModel?> getActiveBatch() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppConstants.tableBatches,
      where: 'isCurrentActive = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BatchModel.fromMap(rows.first);
  }

  @override
  Future<List<BatchModel>> getAllBatches() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppConstants.tableBatches,
      orderBy: 'createdAt DESC',
    );
    return rows.map(BatchModel.fromMap).toList();
  }

  @override
  Future<void> setActiveBatch(String batchId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        AppConstants.tableBatches,
        {'isCurrentActive': 0},
        where: 'isCurrentActive = 1',
      );
      final count = await txn.update(
        AppConstants.tableBatches,
        {'isCurrentActive': 1},
        where: 'id = ?',
        whereArgs: [batchId],
      );
      if (count == 0) {
        throw DatabaseOperationException('Batch not found: $batchId');
      }
    });
  }

  // =====================================================================
  // DISPENSE
  // =====================================================================

  @override
  Future<DispenseResult> dispenseVouchers(int count) async {
    if (count <= 0) {
      throw ArgumentError.value(count, 'count', 'must be positive');
    }

    final db = await _dbHelper.database;
    final activeBatch = await getActiveBatch();
    if (activeBatch == null) {
      throw const NoActiveBatchException();
    }

    final transactionId = _uuid.v4();
    late List<Voucher> dispensed;

    try {
      await db.transaction((txn) async {
        // Lock in the candidate rows first, inside the transaction, so
        // a concurrent dispense call cannot select the same rows -
        // SQLite's transaction isolation guarantees this read+write is
        // atomic w.r.t. other writers.
        final rows = await txn.query(
          AppConstants.tableVouchers,
          where: 'batchId = ? AND status = ?',
          whereArgs: [activeBatch.id, AppConstants.statusAvailable],
          orderBy: 'id ASC',
          limit: count,
        );

        if (rows.length < count) {
          throw InsufficientStockException(
              requested: count, available: rows.length);
        }

        final now = DateTime.now();
        dispensed = [];

        for (final row in rows) {
          final voucher = Voucher.fromMap(row);
          final updated = voucher.copyWith(
            status: VoucherStatus.sold,
            soldAt: now,
            transactionId: transactionId,
          );
          await txn.update(
            AppConstants.tableVouchers,
            updated.toMap(),
            where: 'id = ?',
            whereArgs: [voucher.id],
          );
          dispensed.add(updated);
        }

        final newSoldCount = activeBatch.soldVouchers + dispensed.length;
        final isNowSoldOut = newSoldCount >= activeBatch.totalVouchers;

        await txn.update(
          AppConstants.tableBatches,
          {
            'soldVouchers': newSoldCount,
            if (isNowSoldOut) 'completedAt': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [activeBatch.id],
        );
      });
    } on InsufficientStockException {
      rethrow;
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    _lastTransactionId = transactionId;

    final message = _buildClipboardMessage(dispensed);

    return DispenseResult(
      vouchers: dispensed,
      clipboardMessage: message,
      transactionId: transactionId,
    );
  }

  String _buildClipboardMessage(List<Voucher> vouchers) {
    final buffer = StringBuffer();
    for (int i = 0; i < vouchers.length; i++) {
      final numeral = i < vouchers.length ? i + 1 : '${i + 1}.';
      final v = vouchers[i];
      buffer.writeln('$numeral: User: ${v.username} | Pass: ${v.password}');
    }
    return buffer.toString().trim();
  }

  // =====================================================================
  // UNDO
  // =====================================================================

  @override
  Future<void> undoLastTransaction() async {
    final txId = _lastTransactionId;

    if (txId == null) {
      throw const UndoNotAvailableException();
    }

    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        final rows = await txn.query(
          AppConstants.tableVouchers,
          where: 'transactionId = ? AND status = ?',
          whereArgs: [txId, AppConstants.statusSold],
        );

        if (rows.isEmpty) {
          throw const UndoNotAvailableException();
        }

        final batchId = rows.first['batchId'] as String;

        await txn.update(
          AppConstants.tableVouchers,
          {
            'status': AppConstants.statusAvailable,
            'soldAt': null,
            'transactionId': null,
          },
          where: 'transactionId = ?',
          whereArgs: [txId],
        );

        final batchRows = await txn.query(
          AppConstants.tableBatches,
          where: 'id = ?',
          whereArgs: [batchId],
        );
        if (batchRows.isNotEmpty) {
          final batch = BatchModel.fromMap(batchRows.first);
          final restoredSoldCount =
              (batch.soldVouchers - rows.length).clamp(0, batch.totalVouchers);
          await txn.update(
            AppConstants.tableBatches,
            {
              'soldVouchers': restoredSoldCount,
              // If the batch had been marked complete but we just
              // undid a sale, it's no longer sold out.
              'completedAt': restoredSoldCount >= batch.totalVouchers
                  ? batch.completedAt?.toIso8601String()
                  : null,
            },
            where: 'id = ?',
            whereArgs: [batchId],
          );
        }
      });
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    _lastTransactionId = null;
  }

  // =====================================================================
  // SYNC OFFSET
  // =====================================================================

  @override
  Future<int> syncOffset({
    required String batchId,
    required int offsetIndex,
  }) async {
    if (offsetIndex <= 1) return 0; // لا يوجد شيء لتعليمه
    final db = await _dbHelper.database;
    int updatedCount = 0;

    try {
      await db.transaction((txn) async {
        // جلب كل البطاقات AVAILABLE مرتبة ترتيباً تصاعدياً (الإدراج الأصلي)
        // نأخذ (offsetIndex - 1) أول بطاقة AVAILABLE لتعليمها SOLD
        final rows = await txn.rawQuery(
          '''
          SELECT id FROM ${AppConstants.tableVouchers}
          WHERE batchId = ?
          ORDER BY id ASC
          LIMIT ?
          ''',
          [batchId, offsetIndex - 1],
        );

        if (rows.isEmpty) return;

        final ids = rows.map((r) => r['id'] as int).toList();
        final placeholders = List.filled(ids.length, '?').join(',');
        final now = DateTime.now().toIso8601String();

        // تعليم جميع هذه البطاقات كـ SOLD بشكل دفعي
        updatedCount = await txn.rawUpdate(
          '''
          UPDATE ${AppConstants.tableVouchers}
          SET status = ?, soldAt = ?, transactionId = ?
          WHERE id IN ($placeholders)
          AND status = ?
          ''',
          [
            AppConstants.statusSold,
            now,
            'SYNC_OFFSET',
            ...ids.map((id) => id.toString()),
            AppConstants.statusAvailable,
          ],
        );

        // تحديث عداد المبيعات في الدفعة
        final batchRows = await txn.query(
          AppConstants.tableBatches,
          where: 'id = ?',
          whereArgs: [batchId],
        );
        if (batchRows.isNotEmpty) {
          final batch = BatchModel.fromMap(batchRows.first);
          final newSoldCount =
              (batch.soldVouchers + updatedCount).clamp(0, batch.totalVouchers);
          final isNowSoldOut = newSoldCount >= batch.totalVouchers;
          await txn.update(
            AppConstants.tableBatches,
            {
              'soldVouchers': newSoldCount,
              if (isNowSoldOut) 'completedAt': now,
            },
            where: 'id = ?',
            whereArgs: [batchId],
          );
        }
      });
    } on DatabaseException catch (e) {
      throw DatabaseOperationException(e.toString());
    }

    return updatedCount;
  }

  @override
  Future<Voucher?> getVoucherAtPosition({
    required String batchId,
    required int position,
  }) async {
    if (position < 1) return null;
    final db = await _dbHelper.database;
    // نستخدم OFFSET (position-1) للحصول على البطاقة ذات الموضع المطلوب
    final rows = await db.rawQuery(
      '''
      SELECT * FROM ${AppConstants.tableVouchers}
      WHERE batchId = ?
      ORDER BY id ASC
      LIMIT 1 OFFSET ?
      ''',
      [batchId, position - 1],
    );
    if (rows.isEmpty) return null;
    return Voucher.fromMap(rows.first);
  }

  // =====================================================================
  // VOID
  // =====================================================================

  @override
  Future<void> voidVoucher(int voucherId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      AppConstants.tableVouchers,
      {'status': AppConstants.statusVoid},
      where: 'id = ? AND status = ?',
      whereArgs: [voucherId, AppConstants.statusAvailable],
    );
    if (count == 0) {
      throw const DatabaseOperationException(
        'لا يمكن إبطال بطاقة مباعة بالفعل أو غير موجودة.',
      );
    }
  }

  // =====================================================================
  // STOCK / ANALYTICS
  // =====================================================================

  @override
  Future<int> getAvailableCount(String batchId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableVouchers} '
      'WHERE batchId = ? AND status = ?',
      [batchId, AppConstants.statusAvailable],
    );
    return _firstIntValue(result) ?? 0;
  }

  @override
  Future<List<Voucher>> getVouchersByStatus(
      String batchId, VoucherStatus status) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppConstants.tableVouchers,
      where: 'batchId = ? AND status = ?',
      whereArgs: [batchId, status.dbValue],
      orderBy: 'id ASC',
    );
    return rows.map(Voucher.fromMap).toList();
  }

  @override
  Future<DailySummary> getDailySummary() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final soldTodayResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableVouchers} '
      'WHERE status = ? AND soldAt >= ?',
      [AppConstants.statusSold, startOfDay],
    );
    final soldToday = _firstIntValue(soldTodayResult) ?? 0;

    final completedBatchesResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableBatches} '
      'WHERE completedAt IS NOT NULL',
    );
    final completedBatches = _firstIntValue(completedBatchesResult) ?? 0;

    final totalBatchesResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableBatches}',
    );
    final totalBatches = _firstIntValue(totalBatchesResult) ?? 0;

    final activeBatch = await getActiveBatch();
    final activeStock =
        activeBatch != null ? await getAvailableCount(activeBatch.id) : 0;

    return DailySummary(
      soldToday: soldToday,
      batchesCompletedTotal: completedBatches,
      currentActiveStock: activeStock,
      totalBatches: totalBatches,
    );
  }

  /// Whether Undo is currently possible (used by UI to enable/disable
  /// the Undo button reactively without triggering the exception path).
  bool get canUndo {
    return _lastTransactionId != null;
  }

  int? _firstIntValue(List<Map<String, Object?>> result) {
    if (result.isEmpty) return null;
    final value = result.first.values.first;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
