import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import '../services/recent_files_service.dart';

class FileProvider extends ChangeNotifier {
  List<RecentFile> _recentFiles = [];
  List<RecentFile> _filteredFiles = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<RecentFile> get recentFiles => _filteredFiles;
  bool get isLoading => _isLoading;

  Future<void> loadRecentFiles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _recentFiles = await RecentFilesService.getRecentFiles();
      _applySearch();
    } catch (e) {
      debugPrint('Error loading files: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchFiles(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredFiles = List.from(_recentFiles);
    } else {
      _filteredFiles = _recentFiles
          .where((file) => file.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  Future<String?> pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
    } catch (e) {
      throw Exception('Failed to pick PDF: $e');
    }
    return null;
  }

  Future<String?> scanDocument() async {
    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        _isLoading = true;
        notifyListeners();

        final output = await getApplicationDocumentsDirectory();
        final fileName = "Scan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf";
        final filePath = "${output.path}/$fileName";
        
        // Heavy PDF generation moved to a background isolate using compute
        await compute(_generatePdfFromImages, {
          'pictures': pictures,
          'outputPath': filePath,
        });
        
        await loadRecentFiles();
        return filePath;
      }
    } catch (e) {
      debugPrint('Error scanning document: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> removeFile(String path) async {
    await RecentFilesService.removeRecentFile(path);
    await loadRecentFiles();
  }

  Future<void> pinFile(String path) async {
    await RecentFilesService.pinToTop(path);
    await loadRecentFiles();
  }
}

/// Helper function for compute to generate PDF in background
Future<void> _generatePdfFromImages(Map<String, dynamic> params) async {
  final List<String> pictures = params['pictures'];
  final String outputPath = params['outputPath'];
  
  final pdf = pw.Document();
  for (final picture in pictures) {
    final file = File(picture);
    if (file.existsSync()) {
      final image = pw.MemoryImage(file.readAsBytesSync());
      pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(image))));
    }
  }
  
  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());
}
