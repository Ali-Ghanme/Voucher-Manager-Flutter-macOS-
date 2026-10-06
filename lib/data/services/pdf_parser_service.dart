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

  List<ExtractedPair> _extractPairsFromText(String text, VoucherFormat format) {
    final List<ExtractedPair> results = [];
    final Set<String> seenKeys = {};

    // 1. تنظيف النص المرجعي وإزالة العبارات والرموز غير الرقمية
    final String cleanText = text
        .replaceAll(
            RegExp(
                r'Fast\s*Net|FastNet|شيكل|ساعات|3M|نتمنى لكم أوقات ممتعة|تتمنى لكم أوقات ممتعة|لتمنى لكم أوقات ممتعة',
                caseSensitive: false),
            ' ')
        .replaceAll(
            RegExp(r'[^\d]'), ''); // إزالة كل شيء والاستبقاء على الأرقام فقط

    debugPrint(
        '📄 [PDF Raw Digits] طول سلسلة الأرقام الإجمالية: ${cleanText.length}');

    // 2. مطابقة عامة: أي 6 أرقام (اسم مستخدم) متبوعة بـ 4 أرقام (كلمة مرور)
    // هذا يدعم البادئات (70 و 42 وأي بادئة مستقبليّة)
    final RegExp generalVoucherRegex = RegExp(r'(\d{6})(\d{4})');

    final matches = generalVoucherRegex.allMatches(cleanText);

    for (final match in matches) {
      final String username = match.group(1)!;
      final String password = match.group(2)!;

      final key = '$username|$password';
      if (seenKeys.add(key)) {
        results.add(ExtractedPair(username: username, password: password));
      }
    }

    // 3. Fallback: التجميع المتتابع على مستوى الخانات الفردية إذا تطلب الأمر
    if (results.isEmpty) {
      final List<String> digits = cleanText.split('');
      int i = 0;

      while (i <= digits.length - 10) {
        final username = digits.sublist(i, i + 6).join('');
        final password = digits.sublist(i + 6, i + 10).join('');

        final key = '$username|$password';
        if (seenKeys.add(key)) {
          results.add(ExtractedPair(username: username, password: password));
          i += 10; // القفز للبطاقة التالية
          continue;
        }
        i++;
      }
    }

    debugPrint('🔢 [PDF] نجاح استخراج ${results.length} كرت بنجاح.');
    return results;
  }
}

/// Small typedef alias to keep this file self-contained regardless of
/// which underlying byte-list type File.readAsBytes() returns across
/// dart:io versions.
typedef Uint8ListLike = List<int>;
