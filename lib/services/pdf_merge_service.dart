import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfMergeService {
  static Future<String?> mergePdfs(List<String> paths) async {
    try {
      if (paths.isEmpty) return null;

      // Read all files into bytes first on the main isolate (async)
      List<List<int>> allBytes = [];
      for (final path in paths) {
        final file = File(path);
        if (await file.exists()) {
          allBytes.add(await file.readAsBytes());
        }
      }

      if (allBytes.isEmpty) return null;

      // Perform heavy merging in a background isolate
      final List<int> mergedBytes = await compute(_mergeTask, allBytes);

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File outputFile = File(p.join(directory.path, fileName));
      
      await outputFile.writeAsBytes(mergedBytes);
      return outputFile.path;
    } catch (e) {
      debugPrint("Error merging PDFs: $e");
      return null;
    }
  }

  static List<int> _mergeTask(List<List<int>> allBytes) {
    final PdfDocument finalDoc = PdfDocument();

    for (final bytes in allBytes) {
      final PdfDocument sourceDoc = PdfDocument(inputBytes: bytes);
      for (int i = 0; i < sourceDoc.pages.count; i++) {
        final PdfPage sourcePage = sourceDoc.pages[i];
        final PdfTemplate template = sourcePage.createTemplate();
        final PdfPage page = finalDoc.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      sourceDoc.dispose();
    }

    final List<int> result = finalDoc.saveSync();
    finalDoc.dispose();
    return result;
  }
}
