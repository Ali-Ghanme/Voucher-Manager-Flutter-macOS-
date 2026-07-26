import 'package:equatable/equatable.dart';

import '../../data/models/batch_model.dart';
import '../../data/models/voucher_model.dart';
import '../../domain/repositories/voucher_repository.dart';

/// UI-facing loading/error status. Kept separate from the data itself
/// so the UI can show e.g. a spinner overlay without losing the last
/// good data underneath it.
enum VoucherStatusFlag { initial, loading, ready, error }

class VoucherState extends Equatable {
  final VoucherStatusFlag status;
  final BatchModel? activeBatch;
  final int availableCount;
  final List<Voucher> lastDispensed;
  final String? lastClipboardMessage;
  final bool canUndo;
  final DailySummary? dailySummary;
  final List<BatchModel> allBatches;
  final String? errorMessage;

  const VoucherState({
    this.status = VoucherStatusFlag.initial,
    this.activeBatch,
    this.availableCount = 0,
    this.lastDispensed = const [],
    this.lastClipboardMessage,
    this.canUndo = false,
    this.dailySummary,
    this.allBatches = const [],
    this.errorMessage,
  });

  bool get hasActiveBatch => activeBatch != null;
  bool get isBatchSoldOut => activeBatch?.isSoldOut ?? false;

  VoucherState copyWith({
    VoucherStatusFlag? status,
    BatchModel? activeBatch,
    bool clearActiveBatch = false,
    int? availableCount,
    List<Voucher>? lastDispensed,
    String? lastClipboardMessage,
    bool? canUndo,
    DailySummary? dailySummary,
    List<BatchModel>? allBatches,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoucherState(
      status: status ?? this.status,
      activeBatch: clearActiveBatch ? null : (activeBatch ?? this.activeBatch),
      availableCount: availableCount ?? this.availableCount,
      lastDispensed: lastDispensed ?? this.lastDispensed,
      lastClipboardMessage: lastClipboardMessage ?? this.lastClipboardMessage,
      canUndo: canUndo ?? this.canUndo,
      dailySummary: dailySummary ?? this.dailySummary,
      allBatches: allBatches ?? this.allBatches,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeBatch,
        availableCount,
        lastDispensed,
        lastClipboardMessage,
        canUndo,
        dailySummary,
        allBatches,
        errorMessage,
      ];
}
