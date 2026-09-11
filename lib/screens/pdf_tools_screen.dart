import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:intl/intl.dart';

import '../providers/file_provider.dart';
import '../services/pdf_tools_service.dart';
import '../services/recent_files_service.dart';

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  bool _isProcessing = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleTool(String toolType) async {
    final provider = context.read<FileProvider>();
    final path = await provider.pickPDF();
    if (path == null) return;

    if (!context.mounted) return;

    if (toolType == 'Split') {
      _showSplitDialog(path);
    } else if (toolType == 'Protect') {
      _showProtectDialog(path);
    } else if (toolType == 'Watermark') {
      _showWatermarkDialog(path);
    }
  }

  void _showSplitDialog(String path) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter page numbers (e.g. 1,2,5)',
            helperText: '1-based indexing',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) return;
              final indices = input.split(',').map((e) => int.tryParse(e.trim()) ?? -1).where((e) => e > 0).map((e) => e - 1).toList();
              if (indices.isEmpty) return;
              
              Navigator.pop(context);
              _processTool(() => PdfToolsService.splitPdf(path, indices));
            },
            child: const Text('Split'),
          ),
        ],
      ),
    );
  }

  void _showProtectDialog(String path) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Protect'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              _processTool(() => PdfToolsService.protectPdf(path, controller.text));
            },
            child: const Text('Protect'),
          ),
        ],
      ),
    );
  }

  void _showWatermarkDialog(String path) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Watermark'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter watermark text'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              _processTool(() => PdfToolsService.addWatermark(path, controller.text));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTool(Future<String> Function() action) async {
    setState(() => _isProcessing = true);
    try {
      final outputPath = await action();
      final file = File(outputPath);
      final size = "${(await file.length() / (1024 * 1024)).toStringAsFixed(2)} MB";
      final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
      
      await RecentFilesService.addRecentFile(RecentFile(
        path: outputPath,
        name: p.basename(outputPath),
        date: date,
        size: size,
      ));

      if (mounted) {
        context.read<FileProvider>().loadRecentFiles();
        context.push('/pdf-viewer', extra: {
          'path': outputPath,
          'fileName': p.basename(outputPath),
        });
      }
    } catch (e) {
      _showError('Tool failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Utilities', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator())
        : GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _ToolCard(
                icon: Icons.content_cut_rounded,
                title: 'Split PDF',
                subtitle: 'Extract pages',
                color: Colors.blue,
                onTap: () => _handleTool('Split'),
              ),
              _ToolCard(
                icon: Icons.lock_rounded,
                title: 'Protect',
                subtitle: 'Add password',
                color: Colors.redAccent,
                onTap: () => _handleTool('Protect'),
              ),
              _ToolCard(
                icon: Icons.text_fields_rounded,
                title: 'Watermark',
                subtitle: 'Add overlay text',
                color: Colors.orange,
                onTap: () => _handleTool('Watermark'),
              ),
              _ToolCard(
                icon: Icons.merge_type_rounded,
                title: 'Merge',
                subtitle: 'Combine PDFs',
                color: Colors.green,
                onTap: () => context.push('/merge'),
              ),
            ],
          ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
