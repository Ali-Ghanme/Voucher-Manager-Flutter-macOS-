import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Lifecycle states of a single voucher card.
enum VoucherStatus { available, sold, voided }

extension VoucherStatusX on VoucherStatus {
  String get dbValue {
    switch (this) {
      case VoucherStatus.available:
        return AppConstants.statusAvailable;
      case VoucherStatus.sold:
        return AppConstants.statusSold;
      case VoucherStatus.voided:
        return AppConstants.statusVoid;
    }
  }

  static VoucherStatus fromDb(String value) {
    switch (value) {
      case AppConstants.statusSold:
        return VoucherStatus.sold;
      case AppConstants.statusVoid:
        return VoucherStatus.voided;
      case AppConstants.statusAvailable:
      default:
        return VoucherStatus.available;
    }
  }
}

/// A single voucher card (username + password pair) extracted from a
/// PDF batch. Maps 1:1 to a row in the `vouchers` SQLite table.
class Voucher extends Equatable {
  /// Auto-increment primary key. Null until persisted.
  final int? id;

  /// Foreign key -> Batch.id
  final String batchId;

  /// 7-digit username, stored as String to preserve any leading zeros.
  final String username;

  /// 2-3 digit password, stored as String for the same reason.
  final String password;

  final VoucherStatus status;

  final DateTime? soldAt;

  /// Groups vouchers sold together in a single bulk-dispense operation.
  /// Used to power the "Undo last transaction" feature.
  final String? transactionId;

  const Voucher({
    this.id,
    required this.batchId,
    required this.username,
    required this.password,
    this.status = VoucherStatus.available,
    this.soldAt,
    this.transactionId,
  });

  Voucher copyWith({
    int? id,
    String? batchId,
    String? username,
    String? password,
    VoucherStatus? status,
    DateTime? soldAt,
    String? transactionId,
    bool clearSoldAt = false,
    bool clearTransactionId = false,
  }) {
    return Voucher(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      soldAt: clearSoldAt ? null : (soldAt ?? this.soldAt),
      transactionId:
          clearTransactionId ? null : (transactionId ?? this.transactionId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'batchId': batchId,
      'username': username,
      'password': password,
      'status': status.dbValue,
      'soldAt': soldAt?.toIso8601String(),
      'transactionId': transactionId,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] as int?,
      batchId: map['batchId'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      status: VoucherStatusX.fromDb(map['status'] as String),
      soldAt: map['soldAt'] != null ? DateTime.parse(map['soldAt'] as String) : null,
      transactionId: map['transactionId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, batchId, username, password, status, soldAt, transactionId];
}
