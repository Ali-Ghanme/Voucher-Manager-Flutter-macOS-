import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/error/exceptions.dart';
import '../../core/utils/regex_patterns.dart';

/// Extracts (username, password) voucher pairs from a PDF file's raw
/// text content.
///
/// Strategy:
/// 1. Extract full text from every page via Syncfusion's PDF text
///    extractor (works for both single- and multi-page voucher sheets).
/// 2. Tokenize the text into all numeric runs of 2-7 digits, preserving
///    document order (this is layout-agnostic - it doesn't matter if
///    the PDF uses a table, a grid, or plain lines).
/// 3. Walk the tokens; whenever a 7-digit token (username) is found,
///    look at the *next* token - if it is 2-3 digits, pair them as one
///    voucher. This naturally skips over page numbers, headers, dates,
///    etc. that don't fit the username/password adjacency pattern.
class PdfParserService {
  /// Parses [file] and returns the list of extracted username/password
  /// pairs, in the order they appear in the document.
  ///
  /// Throws [EmptyPdfException] if no text could be extracted at all.
  /// Throws [RegexMismatchException] if text was extracted but no valid
  /// username/password pairs could be formed.
  Future<List<ExtractedPair>> extractVouchersFromPdf(File file) async {
    final Uint8ListLike bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    String fullText;
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      fullText = extractor.extractText();
    } finally {
      document.dispose();
    }

    if (fullText.trim().isEmpty) {
      throw const EmptyPdfException();
    }

    final List<ExtractedPair> pairs = _extractPairsFromText(fullText);

    if (pairs.isEmpty) {
      throw const RegexMismatchException();
    }

    return pairs;
  }

  /// Core tokenizing/pairing algorithm, split out for unit testability
  /// without needing an actual PDF file.
  List<ExtractedPair> _extractPairsFromText(String text) {
    final List<String> tokens =
        RegexPatterns.anyNumberToken.allMatches(text).map((m) => m.group(0)!).toList();

    final List<ExtractedPair> results = [];
    final Set<String> seenKeys = {};

    int i = 0;
    while (i < tokens.length) {
      final String current = tokens[i];
      final bool isUsername = current.length == 7;

      if (isUsername && i + 1 < tokens.length) {
        final String next = tokens[i + 1];
        final bool nextIsPassword = next.length == 2 || next.length == 3;

        if (nextIsPassword) {
          final key = '$current|$next';
          // Guard against the exact same pair appearing twice due to
          // duplicated PDF text layers (common with some generators).
          if (seenKeys.add(key)) {
            results.add(ExtractedPair(username: current, password: next));
          }
          i += 2; // consume both tokens
          continue;
        }
      }
      i += 1;
    }

    return results;
  }
}

/// Small typedef alias to keep this file self-contained regardless of
/// which underlying byte-list type File.readAsBytes() returns across
/// dart:io versions.
typedef Uint8ListLike = List<int>;
