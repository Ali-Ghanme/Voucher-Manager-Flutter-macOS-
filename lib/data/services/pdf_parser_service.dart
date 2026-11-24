import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:voucher_manager/core/utils/regex_patterns.dart';

import '../../core/error/exceptions.dart';
import '../models/voucher_format.dart';

class PdfParserService {
  Future<List<ExtractedPair>> extractVouchersFromPdf(
    File file, {
    required VoucherFormat format,
  }) async {
    final Uint8ListLike bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    String fullText;
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      fullText = extractor.extractText();
    } finally {
      document.dispose();
    }

    debugPrint('📄 [PDF] طول النص المستخرج: ${fullText.length} حرف');

    if (fullText.trim().isEmpty) {
      debugPrint('❌ [PDF] الملف فارغ أو لا يحتوي على نص');
      throw const EmptyPdfException();
    }

    final List<ExtractedPair> pairs = _extractPairsFromText(fullText, format);
    debugPrint('🔢 [PDF] عدد الأزواج المستخرجة: ${pairs.length}');

    if (pairs.isEmpty) {
      debugPrint('❌ [PDF] لم يتم العثور على أي زوج يطابق الصيغة المطلوبة');
      throw const RegexMismatchException();
    }

    return pairs;
  }

  /// تحويل الأرقام المشرقية/العربية (٠-٩) إلى أرقام غربية (0-9)
  static String _normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    return input.split('').map((char) {
      final idx1 = arabicIndic.indexOf(char);
      if (idx1 != -1) return idx1.toString();
      final idx2 = easternArabicIndic.indexOf(char);
      if (idx2 != -1) return idx2.toString();
      return char;
    }).join('');
  }

  List<ExtractedPair> _extractPairsFromText(String text, VoucherFormat format) {
    List<ExtractedPair> pairs = _parsePairsWithFormat(text, format);

    // إذا لم يتم العثور على أزواج بالصيغة المحددة، وكانت مختلفة عن نمط 5/4،
    // يتم تجربة نمط 5/4 تلقائياً كحماية ذكية في حال نسيان المستخدم تغيير الصيغة
    if (pairs.isEmpty &&
        (format.usernameLength != 5 ||
            format.passwordMinLength != 4 ||
            format.passwordMaxLength != 4)) {
      debugPrint(
          '⚠️ [PDF] لم يتم العثور على أزواج بالصيغة المحددة، تجربة نمط 5/4 تلقائياً...');
      final fallbackPairs =
          _parsePairsWithFormat(text, VoucherFormat.standard54);
      if (fallbackPairs.isNotEmpty) {
        debugPrint(
            '✅ [PDF] تم استخراج ${fallbackPairs.length} كرت بنجاح عبر نمط 5/4.');
        pairs = fallbackPairs;
      }
    }

    return pairs;
  }

  List<ExtractedPair> _parsePairsWithFormat(String text, VoucherFormat format) {
    // 1. تحويل الأرقام المشرقية/العربية إلى إنجليزية
    final String cleanText = _normalizeDigits(text);

    // 2. استخراج سلسلة الأرقام الصافية الكاملة
    final String digits = cleanText.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('📄 [PDF Raw Digits] طول سلسلة الأرقام: ${digits.length}');

    final int uLen = format.usernameLength;
    final int pLen = format.passwordMinLength;
    final int voucherLen = uLen + pLen; // 5 + 4 = 9

    final List<ExtractedPair> pairs = [];

    // 3. التقطيع المباشر (Chunking) لكل كرت بدقة
    for (int i = 0; i <= digits.length - voucherLen; i += voucherLen) {
      pairs.add(ExtractedPair(
        username: digits.substring(i, i + uLen),
        password: digits.substring(i + uLen, i + voucherLen),
      ));
    }

    debugPrint('🔢 [PDF] تم استخراج ${pairs.length} كرت بنجاح.');
    return pairs;
  }
}

/// Small typedef alias to keep this file self-contained regardless of
/// which underlying byte-list type File.readAsBytes() returns across
/// dart:io versions.
typedef Uint8ListLike = List<int>;
