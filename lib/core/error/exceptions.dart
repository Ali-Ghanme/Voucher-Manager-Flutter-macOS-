/// Domain-specific exceptions. Using typed exceptions (instead of raw
/// Strings or generic Exception) lets the UI layer branch on `is X`
/// and show tailored messages/dialogs.
library;

/// Thrown when a PDF is selected but contains no extractable
/// username/password pairs.
class EmptyPdfException implements Exception {
  final String message;
  const EmptyPdfException([this.message = 'لم يتم العثور على أي بطاقات في ملف PDF المحدد.']);

  @override
  String toString() => message;
}

/// Thrown when the regex engine cannot confidently pair usernames with
/// passwords (e.g. mismatched counts).
class RegexMismatchException implements Exception {
  final String message;
  const RegexMismatchException([
    this.message = 'تعذر مطابقة أسماء المستخدمين مع كلمات المرور بشكل صحيح.',
  ]);

  @override
  String toString() => message;
}

/// Thrown when a requested dispense quantity exceeds available stock.
class InsufficientStockException implements Exception {
  final int requested;
  final int available;
  InsufficientStockException({required this.requested, required this.available});

  @override
  String toString() =>
      'المخزون غير كافٍ! المطلوب: $requested، المتوفر: $available.';
}

/// Thrown when a database operation fails or the DB is locked/busy.
class DatabaseOperationException implements Exception {
  final String message;
  const DatabaseOperationException(this.message);

  @override
  String toString() => 'خطأ في قاعدة البيانات: $message';
}

/// Thrown when an Undo is attempted after the undo window has expired,
/// or when there is no last transaction to undo.
class UndoNotAvailableException implements Exception {
  final String message;
  const UndoNotAvailableException([
    this.message = 'لا توجد عملية بيع حديثة يمكن التراجع عنها.',
  ]);

  @override
  String toString() => message;
}

/// Thrown when trying to dispense/import while there is no active batch.
class NoActiveBatchException implements Exception {
  final String message;
  const NoActiveBatchException([this.message = 'لا توجد دفعة نشطة حالياً. الرجاء استيراد ملف PDF أولاً.']);

  @override
  String toString() => message;
}
