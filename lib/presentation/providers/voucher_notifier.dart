import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/exceptions.dart';
import '../../data/models/voucher_format.dart';
import '../../data/repositories/voucher_repository_impl.dart';
import '../../domain/repositories/voucher_repository.dart';
import 'repository_providers.dart';
import 'voucher_state.dart';

final voucherNotifierProvider =
    StateNotifierProvider<VoucherNotifier, VoucherState>((ref) {
  return VoucherNotifier(
    repository: ref.watch(voucherRepositoryProvider),
    repositoryImpl: ref.watch(voucherRepositoryImplProvider),
  );
});

/// Orchestrates all voucher/batch use-cases for the UI layer. Talks
/// only to the [VoucherRepository] abstraction (plus the concrete impl
/// for the `canUndo` convenience getter), never to the database
/// directly - keeping Clean Architecture boundaries intact.
class VoucherNotifier extends StateNotifier<VoucherState> {
  final VoucherRepository _repository;
  final VoucherRepositoryImpl _repositoryImpl;

  VoucherNotifier({
    required VoucherRepository repository,
    required VoucherRepositoryImpl repositoryImpl,
  })  : _repository = repository,
        _repositoryImpl = repositoryImpl,
        super(const VoucherState()) {
    refresh();
  }

  // ---------------------------------------------------------------------
  // Refresh / bootstrap
  // ---------------------------------------------------------------------

  Future<void> refresh() async {
    state = state.copyWith(status: VoucherStatusFlag.loading, clearError: true);
    try {
      final activeBatch = await _repository.getActiveBatch();
      final availableCount =
          activeBatch != null ? await _repository.getAvailableCount(activeBatch.id) : 0;
      final summary = await _repository.getDailySummary();
      final batches = await _repository.getAllBatches();

      state = state.copyWith(
        status: VoucherStatusFlag.ready,
        activeBatch: activeBatch,
        clearActiveBatch: activeBatch == null,
        availableCount: availableCount,
        dailySummary: summary,
        allBatches: batches,
        canUndo: _repositoryImpl.canUndo,
      );
    } catch (e) {
      state = state.copyWith(status: VoucherStatusFlag.error, errorMessage: e.toString());
    }
  }

  // ---------------------------------------------------------------------
  // Import PDF
  // ---------------------------------------------------------------------

  /// Opens a native macOS file picker, then imports the selected PDF.
  /// Returns true on success so the UI can show a success dialog.
  Future<bool> pickAndImportPdf({required VoucherFormat format}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'اختر ملف PDF يحتوي على بطاقات الفاوتشر',
    );

    if (result == null || result.files.single.path == null) {
      return false; // user cancelled
    }

    final file = File(result.files.single.path!);
    return importPdf(file, format: format);
  }

  /// Importable directly with a [File] - useful for testing or
  /// drag-and-drop support.
  Future<bool> importPdf(File file, {required VoucherFormat format}) async {
    state = state.copyWith(status: VoucherStatusFlag.loading, clearError: true);
    debugPrint('📥 [Import] بدء استيراد: ${file.path}');
    debugPrint('⚙️ [Import] الصيغة: username=${format.usernameLength} خانة, password=${format.passwordMinLength}-${format.passwordMaxLength} خانة');
    try {
      await _repository.importPdfBatch(file, format: format);
      await refresh();
      debugPrint('✅ [Import] تم الاستيراد بنجاح');
      return true;
    } on EmptyPdfException catch (e, st) {
      debugPrint('❌ [Import] EmptyPdfException: $e');
      debugPrint('❌ Stack: $st');
      state = state.copyWith(status: VoucherStatusFlag.error, errorMessage: e.toString());
    } on RegexMismatchException catch (e, st) {
      debugPrint('❌ [Import] RegexMismatchException: $e');
      debugPrint('❌ Stack: $st');
      state = state.copyWith(status: VoucherStatusFlag.error, errorMessage: e.toString());
    } on DatabaseOperationException catch (e, st) {
      debugPrint('❌ [Import] DatabaseOperationException: $e');
      debugPrint('❌ Stack: $st');
      state = state.copyWith(status: VoucherStatusFlag.error, errorMessage: e.toString());
    } catch (e, st) {
      debugPrint('❌ [Import] خطأ غير متوقع: $e');
      debugPrint('❌ Stack: $st');
      state = state.copyWith(status: VoucherStatusFlag.error, errorMessage: e.toString());
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Dispense
  // ---------------------------------------------------------------------

  Future<bool> dispense(int count) async {
    state = state.copyWith(clearError: true);
    try {
      final result = await _repository.dispenseVouchers(count);

      await Clipboard.setData(ClipboardData(text: result.clipboardMessage));

      await refresh();
      state = state.copyWith(
        lastDispensed: result.vouchers,
        lastClipboardMessage: result.clipboardMessage,
        canUndo: true,
      );
      return true;
    } on InsufficientStockException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } on NoActiveBatchException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } on DatabaseOperationException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Undo
  // ---------------------------------------------------------------------

  Future<bool> undoLastTransaction() async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.undoLastTransaction();
      await refresh();
      state = state.copyWith(
        lastDispensed: const [],
        canUndo: false,
      );
      return true;
    } on UndoNotAvailableException catch (e) {
      state = state.copyWith(errorMessage: e.toString(), canUndo: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Void
  // ---------------------------------------------------------------------

  Future<bool> voidVoucher(int voucherId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.voidVoucher(voucherId);
      await refresh();
      return true;
    } on DatabaseOperationException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Batch switching
  // ---------------------------------------------------------------------

  Future<void> switchActiveBatch(String batchId) async {
    await _repository.setActiveBatch(batchId);
    await refresh();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ================================ Delete ===================================
  Future<bool> deleteBatch(String batchId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.deleteBatch(batchId);
      await refresh();
      state = state.copyWith(lastDispensed: const [], canUndo: false);
      return true;
    } on DatabaseOperationException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    return false;
  }

  Future<bool> resetBatch(String batchId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.resetBatch(batchId);
      await refresh();
      state = state.copyWith(lastDispensed: const [], canUndo: false);
      return true;
    } on DatabaseOperationException catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
    return false;
  }



 // =========================== Confirem =======================================
 /// يُستخدم بعد إرسال البطاقات فعلياً (مثلاً عبر واتساب) لإخفائها من
  /// اللوحة فقط، لمنع الالتباس وإرسال نفس البطاقات مرة ثانية بالخطأ.
  /// لا يغيّر أي شيء في قاعدة البيانات - البيع يبقى مسجلاً كما هو.
  void confirmSent() {
    state = state.copyWith(
      lastDispensed: const [],
      canUndo: false, // بعد التأكيد، لم يعد هناك داعٍ لإظهار زر التراجع
      clearError: true,
    );
  }
}
