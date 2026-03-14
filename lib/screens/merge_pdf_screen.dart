import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<File> _selectedFiles = [];
  bool _isMerging = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
        });
      }
    } catch (e) {
      _showError('Failed to pick files: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _mergeFiles() async {
    if (_selectedFiles.length < 2) {
      _showError('Please select at least 2 files to merge');
      return;
    }

    setState(() => _isMerging = true);

    try {
      final pdf = pw.Document();
      for (var file in _selectedFiles) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Text("Merged Content from: ${p.basename(file.path)}"),
            ),
          ),
        );
      }

      final output = await getApplicationDocumentsDirectory();
      final fileName = "merged_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      context.pushReplacement('/pdf-viewer', extra: {
        'path': file.path,
        'fileName': fileName,
      });
    } catch (e) {
      _showError('Error during merging: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Merge PDFs', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.merge_type_rounded, size: 80, color: colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No files selected',
                          style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedFiles.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _selectedFiles.removeAt(oldIndex);
                        _selectedFiles.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return Card(
                        key: ValueKey(file.path),
                        color: colorScheme.surfaceContainerLow,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text(p.basename(file.path), style: TextStyle(color: colorScheme.onSurface)),
                          subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.3)),
                            onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX();
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Files'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isMerging ? null : _mergeFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isMerging
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Merge Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
