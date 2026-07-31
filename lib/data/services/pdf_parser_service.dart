import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/regex_patterns.dart';
import '../models/voucher_format.dart';

class PdfParserService {
  Future<List<ExtractedPair>> extractVouchersFromPdf(
    File file, {
    required VoucherFormat format,
  }) async {
    final bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    String fullText;
    try {
      final extractor = PdfTextExtractor(document);
      fullText = extractor.extractText();
    } finally {
      document.dispose();
    }

    debugPrint('📄 Extracted text length: ${fullText.length}');
    debugPrint(
      '📄 First 300 chars:\n${fullText.substring(0, fullText.length < 300 ? fullText.length : 300)}',
    );

    if (fullText.trim().isEmpty) {
      throw const EmptyPdfException();
    }

    final tokens = RegexPatterns.anyNumberToken
        .allMatches(fullText)
        .map((m) => m.group(0)!)
        .toList();
    debugPrint(
        '🔢 Tokens found (${tokens.length}): ${tokens.take(30).join(", ")}'
        '${tokens.length > 30 ? " ..." : ""}');
    debugPrint(
      '⚙️ Expected format: username=${format.usernameLength} digits, '
      'password=${format.passwordMinLength}-${format.passwordMaxLength} digits',
    );

    final pairs = _extractPairsFromText(fullText, format);
    debugPrint('✅ Pairs matched: ${pairs.length}');

    if (pairs.isEmpty) {
      throw const RegexMismatchException();
    }

    return pairs;
  }

  List<ExtractedPair> _extractPairsFromText(String text, VoucherFormat format) {
    final tokens = RegexPatterns.anyNumberToken
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();

    final List<ExtractedPair> results = [];
    final Set<String> seenKeys = {};

    int i = 0;
    while (i < tokens.length) {
      final current = tokens[i];
      final isUsername = current.length == format.usernameLength;

      if (isUsername && i + 1 < tokens.length) {
        final next = tokens[i + 1];
        final nextIsPassword = next.length >= format.passwordMinLength &&
            next.length <= format.passwordMaxLength;

        if (nextIsPassword) {
          final key = '$current|$next';
          if (seenKeys.add(key)) {
            results.add(ExtractedPair(username: current, password: next));
          }
          i += 2;
          continue;
        }
      }
      i += 1;
    }

    return results;
  }
}

typedef Uint8ListLike = List<int>;
