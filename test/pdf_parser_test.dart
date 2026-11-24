import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:voucher_manager/data/models/voucher_format.dart';
import 'package:voucher_manager/data/services/pdf_parser_service.dart';

void main() {
  late PdfParserService service;

  setUp(() {
    service = PdfParserService();
  });

  test('PdfParserService extracts 500 cards from 4500 pure digits via chunking', () async {
    final doc = PdfDocument();
    final font = PdfStandardFont(PdfFontFamily.helvetica, 7);

    // 500 cards x 9 digits = 4500 digits
    final page = doc.pages.add();
    final sb = StringBuffer();
    for (int i = 0; i < 500; i++) {
      final user = (70000 + i).toString();
      final pass = (1000 + i).toString();
      sb.write('$user$pass');
    }
    page.graphics.drawString(sb.toString(), font);

    final bytes = doc.saveSync();
    doc.dispose();

    final tempFile = File('${Directory.systemTemp.path}/test_chunking_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await tempFile.writeAsBytes(bytes);

    try {
      final pairs = await service.extractVouchersFromPdf(
        tempFile,
        format: VoucherFormat.standard54,
      );

      expect(pairs.length, 500);
      expect(pairs.first.username, '70000');
      expect(pairs.first.password, '1000');
      expect(pairs.last.username, '70499');
      expect(pairs.last.password, '1499');
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  });
}
