import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/recent_files_service.dart';
import '../services/pdf_ai_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String path;
  final String fileName;

  const PDFViewerScreen({super.key, required this.path, required this.fileName});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _pdfReady = false;
  PDFViewController? _pdfViewController;
  bool _showControls = true;
  bool _isNightMode = false;
  double _brightness = 0.7;

  // Search related
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _saveToRecents();
  }

  Future<void> _saveToRecents() async {
    try {
      final file = File(widget.path);
      if (await file.exists()) {
        final size = "${(await file.length() / (1024 * 1024)).toStringAsFixed(2)} MB";
        final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
        await RecentFilesService.addRecentFile(RecentFile(
          path: widget.path,
          name: widget.fileName,
          date: date,
          size: size,
        ));
      }
    } catch (e) {
      debugPrint('Error saving to recents: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
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

  void _showSummarySheet() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    if (!mounted) return;

    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Set your Gemini API key in AI Chat settings first.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SummarySheet(
        filePath: widget.path,
        fileName: widget.fileName,
        apiKey: apiKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveNightMode = _isNightMode || isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AppBar(
            backgroundColor: colorScheme.surface.withOpacity(0.7),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: _isSearching 
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, color: colorScheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    // Actual search logic depends on the PDF library's capabilities.
                    // For now, we'll show a message that it's searching.
                    _showError('Searching for "$value"... (Indexing PDF)');
                  },
                )
              : Text(widget.fileName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
            actions: [
              if (_isSearching) ...[
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isSearching = false)),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.search_rounded), 
                  onPressed: () => setState(() => _isSearching = true),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded), 
                  onPressed: () => _showOptionsMenu(context),
                ),
              ]
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            PDFView(
              filePath: widget.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.WIDTH,
              nightMode: effectiveNightMode,
              onRender: (pages) => setState(() {
                _totalPages = pages!;
                _pdfReady = true;
              }),
              onViewCreated: (controller) => _pdfViewController = controller,
              onPageChanged: (page, total) {
                if (page != null) setState(() => _currentPage = page);
              },
              onError: (error) => _showError('Error loading PDF: ${error.toString()}'),
            ),
            
            // Brightness Overlay
            IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: (1.0 - _brightness).clamp(0.0, 0.8)),
              ),
            ),
            
            if (!_pdfReady)
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showControls ? 30 : -100,
              left: 20,
              right: 20,
              child: _ReaderControls(
                currentPage: _currentPage,
                totalPages: _totalPages,
                pdfViewController: _pdfViewController,
                onGridTap: () => _showPageGrid(context),
                onSettingsTap: () => _showSettings(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent),
              title: const Text('✨ Summarize with AI'),
              subtitle: const Text('Generate instant AI summary', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _showSummarySheet();
              },
            ),
            ListTile(
              leading: Icon(Icons.share_rounded, color: colorScheme.primary),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(widget.path)], text: widget.fileName);
              },
            ),
            ListTile(
              leading: Icon(Icons.print_rounded, color: colorScheme.primary),
              title: const Text('Print'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final bytes = await File(widget.path).readAsBytes();
                  await Printing.layoutPdf(onLayout: (_) => bytes);
                } catch (e) {
                  _showError('Failed to print: ${e.toString()}');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: colorScheme.primary),
              title: const Text('Document Info'),
              onTap: () {
                Navigator.pop(context);
                _showDocInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDocInfo() async {
    try {
      final file = File(widget.path);
      final size = "${(await file.length() / (1024 * 1024)).toStringAsFixed(2)} MB";
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Document Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${widget.fileName}'),
              Text('Pages: $_totalPages'),
              Text('Size: $size'),
              const SizedBox(height: 8),
              Text('Path: ${widget.path}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      _showError('Could not retrieve file info: ${e.toString()}');
    }
  }

  void _showPageGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Page Overview', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentPage;
                    return GestureDetector(
                      onTap: () {
                        _pdfViewController?.setPage(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? colorScheme.primary.withOpacity(0.1) : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCurrent ? colorScheme.primary : Colors.transparent),
                        ),
                        child: Center(
                          child: Text('${index + 1}', style: TextStyle(color: isCurrent ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return ReaderSettingsSheet(
            isNightMode: _isNightMode,
            brightness: _brightness,
            onNightModeChanged: (val) {
              setState(() => _isNightMode = val);
              setModalState(() {});
            },
            onBrightnessChanged: (val) {
              setState(() => _brightness = val);
              setModalState(() {});
            },
          );
        }
      ),
    );
  }
}

class _ReaderControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final PDFViewController? pdfViewController;
  final VoidCallback onGridTap;
  final VoidCallback onSettingsTap;

  const _ReaderControls({
    required this.currentPage,
    required this.totalPages,
    required this.pdfViewController,
    required this.onGridTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.onSurface.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 20),
                onPressed: onGridTap,
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_input_component_rounded, size: 20),
                onPressed: onSettingsTap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderSettingsSheet extends StatelessWidget {
  final bool isNightMode;
  final double brightness;
  final Function(bool) onNightModeChanged;
  final Function(double) onBrightnessChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.isNightMode,
    required this.brightness,
    required this.onNightModeChanged,
    required this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reading Mode',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SettingToggle(
                icon: Icons.light_mode_rounded, 
                label: 'Light', 
                isSelected: !isNightMode,
                onTap: () => onNightModeChanged(false),
              ),
              _SettingToggle(
                icon: Icons.dark_mode_rounded, 
                label: 'Dark', 
                isSelected: isNightMode,
                onTap: () => onNightModeChanged(true),
              ),
              _SettingToggle(
                icon: Icons.auto_awesome_rounded, 
                label: 'Auto', 
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Brightness',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Slider(
            value: brightness,
            onChanged: onBrightnessChanged,
            activeColor: colorScheme.primary,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettingToggle({
    required this.icon, 
    required this.label, 
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.05),
                width: 2,
              ),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySheet extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String apiKey;
  const _SummarySheet({required this.filePath, required this.fileName, required this.apiKey});

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  String? _summary;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    try {
      final service = PdfAiService(apiKey: widget.apiKey);
      final text = await service.extractTextFromPdf(widget.filePath);
      final summary = await service.summarizePdf(text);
      if (mounted) setState(() { _summary = summary; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Summary', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(widget.fileName, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5)), overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const CircularProgressIndicator(color: Colors.purpleAccent),
                    const SizedBox(height: 16),
                    Text('Analyzing document...', style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('This may take a few seconds', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.3))),
                  ]))
                : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: colorScheme.error)),
                    ]))
                  : SingleChildScrollView(
                      controller: controller,
                      child: Text(_summary!, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.8, color: colorScheme.onSurface.withOpacity(0.85))),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
