import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../providers/file_provider.dart';
import '../services/recent_files_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadRecentFiles();
    });
    _searchController.addListener(() {
      context.read<FileProvider>().searchFiles(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickPDF() async {
    try {
      final provider = context.read<FileProvider>();
      final path = await provider.pickPDF();
      if (!mounted) return;
      if (path != null) {
        context.push('/pdf-viewer', extra: {
          'path': path,
          'fileName': p.basename(path),
        }).then((_) {
          if (mounted) context.read<FileProvider>().loadRecentFiles();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: ${e.toString()}');
    }
  }

  Future<void> _handleScan() async {
    try {
      final provider = context.read<FileProvider>();
      final path = await provider.scanDocument();
      if (!mounted) return;
      if (path != null) {
        context.push('/pdf-viewer', extra: {
          'path': path,
          'fileName': p.basename(path),
        }).then((_) {
          if (mounted) context.read<FileProvider>().loadRecentFiles();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFileOptions(RecentFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('Share File'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(file.path)], text: file.name);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
              title: const Text('Remove from Recents'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<FileProvider>().removeFile(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent),
              title: const Text('File Info'),
              onTap: () {
                Navigator.pop(context);
                _showFileInfo(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined, color: Colors.greenAccent),
              title: const Text('Pin to Top'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<FileProvider>().pinFile(file.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(RecentFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('File Details', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoItem('Name', file.name),
            _infoItem('Size', file.size),
            _infoItem('Last Opened', file.date),
            _infoItem('Path', file.path),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13), softWrap: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _AnimatedGlow(color: colorScheme.primary.withOpacity(0.12))),
          Positioned(bottom: 100, left: -80, child: _AnimatedGlow(color: colorScheme.secondary.withOpacity(0.08))),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeader(
                    searchController: _searchController,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: QuickActionsRow(
                      onAction: (label) {
                        if (label == 'Scan') _handleScan();
                        if (label == 'Merge') {
                          context.push('/merge').then((_) {
                            if (mounted) context.read<FileProvider>().loadRecentFiles();
                          });
                        }
                        if (label == 'Smart AI') context.push('/ai-chat');
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Recent Documents',
                      onSeeAll: () => context.push('/library').then((_) {
                        if (mounted) context.read<FileProvider>().loadRecentFiles();
                      }),
                    ),
                  ),
                ),
                Consumer<FileProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    if (provider.recentFiles.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('No files found')),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final file = provider.recentFiles[index];
                            return RecentFileCard(
                              file: {'name': file.name, 'date': file.date, 'size': file.size},
                              index: index,
                              onTap: () => context.push('/pdf-viewer', extra: {
                                'path': file.path,
                                'fileName': file.name,
                              }).then((_) {
                                if (mounted) provider.loadRecentFiles();
                              }),
                              onMore: () => _showFileOptions(file),
                            );
                          },
                          childCount: provider.recentFiles.length,
                        ),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickPDF,
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
        label: const Text('New Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, curve: Curves.easeOutBack),
    );
  }
}

class _AnimatedGlow extends StatelessWidget {
  final Color color;
  const _AnimatedGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 5.seconds, curve: Curves.easeInOut);
  }
}

class DashboardHeader extends StatelessWidget {
  final TextEditingController searchController;

  const DashboardHeader({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Discover Your Files', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                ],
              ),
              CircleAvatar(
                radius: 22, 
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search files...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.24), fontSize: 15),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface, fontSize: 15),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class QuickActionsRow extends StatelessWidget {
  final Function(String) onAction;
  const QuickActionsRow({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'Scan', color: Colors.blueAccent, onTap: () => onAction('Scan')),
        _QuickAction(icon: Icons.auto_awesome_rounded, label: 'Smart AI', color: Colors.purpleAccent, onTap: () => onAction('Smart AI')),
        _QuickAction(icon: Icons.merge_type_rounded, label: 'Merge', color: Colors.orangeAccent, onTap: () => onAction('Merge')),
        _QuickAction(icon: Icons.more_horiz_rounded, label: 'More', color: Colors.grey, onTap: () => onAction('More')),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const SectionHeader({super.key, required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        TextButton(
          onPressed: onSeeAll,
          child: Text('See All', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }
}

class RecentFileCard extends StatelessWidget {
  final Map<String, String> file;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMore;
  const RecentFileCard({super.key, required this.file, required this.index, required this.onTap, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.04))
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file['name']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${file['date']} • ${file['size']}', style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.more_horiz_rounded, color: colorScheme.onSurface.withOpacity(0.24)), onPressed: onMore),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + (index * 80)).ms).slideX(begin: 0.05);
  }
}
