import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:ui';
import 'package:flutter/foundation.dart';

class PdfToolsService {
  static Future<String> splitPdf(String path, List<int> pageIndices) async {
    final List<int> bytes = await File(path).readAsBytes();
    
    final List<int> outputBytes = await compute(_splitTask, {
      'bytes': bytes,
      'indices': pageIndices,
    });

    final directory = await getApplicationDocumentsDirectory();
    final String newPath = p.join(directory.path, '${p.basenameWithoutExtension(path)}_split_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await File(newPath).writeAsBytes(outputBytes);
    return newPath;
  }

  static List<int> _splitTask(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final List<int> pageIndices = params['indices'];
    
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfDocument newDocument = PdfDocument();

    for (int index in pageIndices) {
      newDocument.pages.add().graphics.drawPdfTemplate(
            document.pages[index].createTemplate(),
            const Offset(0, 0),
          );
    }

    final List<int> outputBytes = newDocument.saveSync();
    newDocument.dispose();
    document.dispose();
    return outputBytes;
  }

  static Future<String> protectPdf(String path, String password) async {
    final List<int> bytes = await File(path).readAsBytes();
    
    final List<int> outputBytes = await compute(_protectTask, {
      'bytes': bytes,
      'password': password,
    });

    final directory = await getApplicationDocumentsDirectory();
    final String newPath = p.join(directory.path, '${p.basenameWithoutExtension(path)}_protected.pdf');
    await File(newPath).writeAsBytes(outputBytes);
    return newPath;
  }

  static List<int> _protectTask(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final String password = params['password'];

    final PdfDocument document = PdfDocument(inputBytes: bytes);
    PdfSecurity security = document.security;
    security.userPassword = password;
    security.ownerPassword = 'owner_${DateTime.now().millisecondsSinceEpoch}';
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

    final List<int> outputBytes = document.saveSync();
    document.dispose();
    return outputBytes;
  }

  static Future<String> addWatermark(String path, String watermarkText) async {
    final List<int> bytes = await File(path).readAsBytes();
    
    final List<int> outputBytes = await compute(_watermarkTask, {
      'bytes': bytes,
      'text': watermarkText,
    });

    final directory = await getApplicationDocumentsDirectory();
    final String newPath = p.join(directory.path, '${p.basenameWithoutExtension(path)}_watermarked.pdf');
    await File(newPath).writeAsBytes(outputBytes);
    return newPath;
  }

  static List<int> _watermarkTask(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final String watermarkText = params['text'];

    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 60);
    final Size textSize = font.measureString(watermarkText);

    for (int i = 0; i < document.pages.count; i++) {
      final PdfPage page = document.pages[i];
      final PdfGraphics graphics = page.graphics;
      
      graphics.save();
      graphics.setTransparency(0.3);
      graphics.translateTransform(page.size.width / 2, page.size.height / 2);
      graphics.rotateTransform(-45);
      
      graphics.drawString(
        watermarkText,
        font,
        brush: PdfBrushes.red,
        bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, 0, 0),
      );
      
      graphics.restore();
    }

    final List<int> outputBytes = document.saveSync();
    document.dispose();
    return outputBytes;
  }
}
