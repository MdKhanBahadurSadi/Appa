import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../services/recent_files_service.dart';

class PdfSignatureScreen extends StatefulWidget {
  final String path;
  final String fileName;

  const PdfSignatureScreen({super.key, required this.path, required this.fileName});

  @override
  State<PdfSignatureScreen> createState() => _PdfSignatureScreenState();
}

class _PdfSignatureScreenState extends State<PdfSignatureScreen> {
  late SignatureController _signatureController;
  int _selectedPage = 0;
  int _totalPages = 0;
  bool _isSigning = false;
  Uint8List? _signatureImage;
  Offset _signaturePosition = const Offset(100, 100);
  bool _isPlacing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      setState(() {
        _totalPages = document.pages.count;
      });
      document.dispose();
    } catch (e) {
      debugPrint('Error loading PDF: $e');
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _captureSignature() async {
    if (_signatureController.isEmpty) return;
    final image = await _signatureController.toPngBytes();
    if (image != null) {
      setState(() {
        _signatureImage = image;
        _isSigning = false;
        _isPlacing = true;
      });
    }
  }

  Future<void> _saveSignedPdf() async {
    if (_signatureImage == null) return;

    setState(() => _isSaving = true);

    try {
      final List<int> bytes = await File(widget.path).readAsBytes();
      if (!context.mounted) return;
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfPage page = document.pages[_selectedPage];

      // Draw the signature
      final PdfBitmap bitmap = PdfBitmap(_signatureImage!);
      
      // Calculate coordinates mapping
      // We need to account for the screen size and the PDF page size
      final Size pageSize = page.size;
      final Size screenSize = MediaQuery.of(context).size;
      
      // Subtract AppBar height if necessary, but PDFView usually takes remaining space
      // For simplicity, we use the ratio of the full screen vs PDF page
      final double scaleX = pageSize.width / screenSize.width;
      final double scaleY = pageSize.height / screenSize.height;

      final double x = _signaturePosition.dx * scaleX;
      final double y = _signaturePosition.dy * scaleY;

      page.graphics.drawImage(bitmap, Rect.fromLTWH(x, y, 150 * scaleX, 75 * scaleY));

      final List<int> signedBytes = await document.save();
      document.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final String newFileName = '${p.basenameWithoutExtension(widget.fileName)}_signed.pdf';
      final String newPath = p.join(directory.path, newFileName);
      
      final File newFile = File(newPath);
      await newFile.writeAsBytes(signedBytes);

      // Add to recents
      final size = "${(signedBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB";
      final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
      await RecentFilesService.addRecentFile(RecentFile(
        path: newPath,
        name: newFileName,
        date: date,
        size: size,
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $newFileName'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPlacing ? 'Place Signature' : (_isSigning ? 'Sign' : 'Select Page'), 
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_isPlacing)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _isSaving ? null : _saveSignedPdf,
            ),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isPlacing) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              PDFView(
                filePath: widget.path,
                defaultPage: _selectedPage,
                enableSwipe: false,
                onViewCreated: (controller) {
                  // Lock to the selected page
                  controller.setPage(_selectedPage);
                },
              ),
              Positioned(
                left: _signaturePosition.dx,
                top: _signaturePosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _signaturePosition += details.delta;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Image.memory(_signatureImage!, width: 150, height: 75),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Drag signature to position', 
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Final PDF coordinates will be calculated automatically',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        }
      );
    }

    if (_isSigning) {
      return Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _signatureController.clear(),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _captureSignature,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Choose a page to sign:', 
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => _selectedPage = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedPage == index 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPage == index 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text('${index + 1}')),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () => setState(() => _isSigning = true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Proceed to Sign'),
          ),
        ),
      ],
    );
  }
}
