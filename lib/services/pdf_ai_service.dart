import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PdfAiService {
  final String apiKey;

  PdfAiService({required this.apiKey});

  Future<String> extractTextFromPdf(String filePath) async {
    // Read file bytes
    final List<int> bytes = await File(filePath).readAsBytes();

    // Load the PDF document
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    // Create PDF text extractor to extract text
    PdfTextExtractor extractor = PdfTextExtractor(document);

    // Extract text from the document
    String text = extractor.extractText();

    // Dispose the document
    document.dispose();

    if (text.trim().isEmpty) {
      throw Exception('This PDF is image-based. Text extraction not supported.');
    }

    // Truncate to 12000 characters if longer
    if (text.length > 12000) {
      text = '${text.substring(0, 12000)}...[truncated]';
    }

    return text;
  }

  Future<String> summarizePdf(String pdfText) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    const systemPrompt = '''
You are an expert document analyst.
Given the text content of a PDF, provide a clean, structured summary with:

**📌 Overview** (2-3 sentences — what is this document about?)
**🔑 Key Points** (bullet list of 5-7 most important takeaways)
**📊 Details** (any important figures, dates, names, or data)
**✅ Conclusion** (1-2 sentences — final takeaway)

Be concise, professional, and use markdown formatting.

Document Content:
''';

    final fullPrompt = '$systemPrompt$pdfText';

    final response = await model.generateContent([Content.text(fullPrompt)]);
    return response.text ?? 'Could not generate summary.';
  }
}
