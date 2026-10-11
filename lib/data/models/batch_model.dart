import 'package:equatable/equatable.dart';

/// A batch represents one imported PDF file's worth of vouchers.
/// Only one batch is "active" (isCurrentActive == true) at a time -
/// that's the batch dispensed from by default.
class BatchModel extends Equatable {
  /// Unique batch identifier, e.g. "Batch_2026_07_25_1001".
  final String id;

  final String fileName;
  final int totalVouchers;
  final int soldVouchers;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCurrentActive;

  const BatchModel({
    required this.id,
    required this.fileName,
    required this.totalVouchers,
    this.soldVouchers = 0,
    required this.createdAt,
    this.completedAt,
    this.isCurrentActive = false,
  });

  int get remainingVouchers => totalVouchers - soldVouchers;

  bool get isSoldOut => soldVouchers >= totalVouchers && totalVouchers > 0;

  bool get isCompleted => completedAt != null || isSoldOut;

  double get progress => totalVouchers == 0 ? 0 : soldVouchers / totalVouchers;

  BatchModel copyWith({
    String? id,
    String? fileName,
    int? totalVouchers,
    int? soldVouchers,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCurrentActive,
    bool clearCompletedAt = false,
  }) {
    return BatchModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      totalVouchers: totalVouchers ?? this.totalVouchers,
      soldVouchers: soldVouchers ?? this.soldVouchers,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isCurrentActive: isCurrentActive ?? this.isCurrentActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'totalVouchers': totalVouchers,
      'soldVouchers': soldVouchers,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCurrentActive': isCurrentActive ? 1 : 0,
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map) {
    return BatchModel(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      totalVouchers: map['totalVouchers'] as int,
      soldVouchers: map['soldVouchers'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt:
          map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      isCurrentActive: (map['isCurrentActive'] as int) == 1,
    );
  }

  @override
  List<Object?> get props =>
      [id, fileName, totalVouchers, soldVouchers, createdAt, completedAt, isCurrentActive];
}
