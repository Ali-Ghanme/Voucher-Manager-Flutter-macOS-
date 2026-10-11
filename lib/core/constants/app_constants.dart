/// Central place for constants used across the app.
/// Keeping these in one file avoids "magic numbers/strings" scattered
/// through the codebase and makes tuning behaviour trivial.
library app_constants;

class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------
  // Window sizing
  // ---------------------------------------------------------------------
  static const double normalWindowWidth = 500;
  static const double normalWindowHeight = 900;

  static const double compactWindowWidth = 400;
  static const double compactWindowHeight = 520;

  // ---------------------------------------------------------------------
  // Quick dispense chip values
  // ---------------------------------------------------------------------
  static const List<int> quickDispenseOptions = [1, 2, 5, 10, 20];

  // ---------------------------------------------------------------------
  // Undo window
  // ---------------------------------------------------------------------
  /// How long (in seconds) a sale remains eligible for one-click undo.
  /// After this window the "last transaction" is cleared from memory,
  /// though the DB record itself is untouched (data integrity is never
  /// lost - this only affects the convenience Undo button).
  static const int undoTimeoutSeconds = 120;

  // ---------------------------------------------------------------------
  // Database
  // ---------------------------------------------------------------------
  static const String dbName = 'voucher_manager.db';
  static const int dbVersion = 1;

  static const String tableVouchers = 'vouchers';
  static const String tableBatches = 'batches';

  // ---------------------------------------------------------------------
  // Voucher status values (stored as TEXT in SQLite, mirrored by
  // VoucherStatus enum in voucher_model.dart)
  // ---------------------------------------------------------------------
  static const String statusAvailable = 'AVAILABLE';
  static const String statusSold = 'SOLD';
  static const String statusVoid = 'VOID';

  // ---------------------------------------------------------------------
  // Clipboard message template (Arabic, right-to-left friendly)
  // ---------------------------------------------------------------------
  static const String messageHeader =
      'أهلاً بك! إليك تفاصيل البطاقات الخاصة بك:';
  static const String messageFooter = 'شكراً لتواصلك معنا!';

  /// Emoji numerals used for the numbered list (1..20). Falls back to
  /// plain numbers beyond index 20.
  static const List<String> numberEmojis = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
}
