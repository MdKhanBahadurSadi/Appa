import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_study_models.dart';

class PdfAiService {
  final String apiKey;

  PdfAiService({required this.apiKey});

  Future<String> extractTextFromPdf(String filePath) async {
    final List<int> bytes = await File(filePath).readAsBytes();
    
    String text = await compute(_extractTextTask, bytes);

    if (text.trim().isEmpty) {
      throw Exception('This PDF is image-based. Text extraction not supported.');
    }

    if (text.length > 12000) {
      text = '${text.substring(0, 12000)}...[truncated]';
    }

    return text;
  }

  static String _extractTextTask(List<int> bytes) {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final String text = extractor.extractText();
    document.dispose();
    return text;
  }

  Future<String> extractTextFromPage(String filePath, int pageIndex) async {
    final List<int> bytes = await File(filePath).readAsBytes();
    return await compute(_extractTextFromPageTask, {
      'bytes': bytes,
      'index': pageIndex,
    });
  }

  static String _extractTextFromPageTask(Map<String, dynamic> params) {
    final List<int> bytes = params['bytes'];
    final int index = params['index'];
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final String text = extractor.extractText(startPageIndex: index, endPageIndex: index);
    document.dispose();
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

  Future<List<QuizQuestion>> generateQuiz(String pdfText) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    const systemPrompt = '''
You are an educational assistant. Based on the provided PDF text, generate a quiz with exactly 5 multiple-choice questions.
Return ONLY a valid JSON array of objects with the following structure:
[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctOptionIndex": 0,
    "explanation": "Why this is correct"
  }
]
Document Content:
''';

    final response = await model.generateContent([Content.text('$systemPrompt$pdfText')]);
    final text = response.text ?? '[]';
    
    // Clean up potential markdown formatting from Gemini
    final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final List<dynamic> data = jsonDecode(cleanJson);
    return data.map((e) => QuizQuestion.fromJson(e)).toList();
  }

  Future<List<Flashcard>> generateFlashcards(String pdfText) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    const systemPrompt = '''
You are an educational assistant. Based on the provided PDF text, generate 8-10 study flashcards.
Return ONLY a valid JSON array of objects with the following structure:
[
  {
    "front": "Question or term",
    "back": "Answer or definition"
  }
]
Document Content:
''';

    final response = await model.generateContent([Content.text('$systemPrompt$pdfText')]);
    final text = response.text ?? '[]';
    
    final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final List<dynamic> data = jsonDecode(cleanJson);
    return data.map((e) => Flashcard.fromJson(e)).toList();
  }
}
