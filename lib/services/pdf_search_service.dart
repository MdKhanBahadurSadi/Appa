import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfSearchService {
  static Future<List<int>> searchKeyword(String filePath, String query) async {
    if (query.isEmpty) return [];

    try {
      final List<int> bytes = await File(filePath).readAsBytes();
      
      // Perform heavy text extraction and search in background isolate
      return await compute(_searchTask, {
        'bytes': bytes,
        'query': query,
      });
    } catch (e) {
      debugPrint('Error searching PDF: $e');
      return [];
    }
  }

  static List<int> _searchTask(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final String query = params['query'].toLowerCase();
    final List<int> matchedPages = [];
    
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);

    for (int i = 0; i < document.pages.count; i++) {
      final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (pageText.toLowerCase().contains(query)) {
        matchedPages.add(i);
      }
    }

    document.dispose();
    return matchedPages;
  }
}
