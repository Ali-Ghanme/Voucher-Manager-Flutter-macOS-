/// Describes the digit-length pattern of a specific voucher batch
/// format. Different PDF generators/printers use different lengths,
/// so this is configured per-import rather than hardcoded.
class VoucherFormat {
  final int usernameLength;
  final int passwordMinLength;
  final int passwordMaxLength;

  const VoucherFormat({
    required this.usernameLength,
    required this.passwordMinLength,
    required this.passwordMaxLength,
  });

  /// The original hardcoded format (7-digit username, 2-3 digit password).
  static const VoucherFormat classic = VoucherFormat(
    usernameLength: 7,
    passwordMinLength: 2,
    passwordMaxLength: 3,
  );

  /// The newer shorter format seen in some batches (6-digit username,
  /// 1-digit password).
  static const VoucherFormat compact = VoucherFormat(
    usernameLength: 6,
    passwordMinLength: 1,
    passwordMaxLength: 1,
  );
}