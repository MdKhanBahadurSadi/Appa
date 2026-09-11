import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/vault_service.dart';
import '../services/recent_files_service.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen> {
  bool _isAuthenticated = false;
  List<VaultFile> _vaultFiles = [];

  @override
  void initState() {
    super.initState();
    _startAuth();
  }

  Future<void> _startAuth() async {
    final success = await VaultService.authenticate();
    if (success) {
      setState(() {
        _isAuthenticated = true;
        _vaultFiles = VaultService.getVaultFiles();
      });
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _unlockFile(VaultFile vaultFile) async {
    await VaultService.removeFromVault(vaultFile.vaultPath);
    
    // Add back to recents
    try {
      final file = File(vaultFile.originalPath);
      if (await file.exists()) {
        final size = "${(await file.length() / (1024 * 1024)).toStringAsFixed(2)} MB";
        final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
        await RecentFilesService.addRecentFile(RecentFile(
          path: vaultFile.originalPath,
          name: vaultFile.fileName,
          date: date,
          size: size,
        ));
      }
    } catch (e) {
      debugPrint('Error adding back to recents: $e');
    }

    setState(() {
      _vaultFiles = VaultService.getVaultFiles();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File moved back to original location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Vault', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open_rounded),
            onPressed: () => setState(() => _isAuthenticated = false),
          ),
        ],
      ),
      body: _vaultFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('Vault is Empty', style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Move private files here from dashboard options', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vaultFiles.length,
              itemBuilder: (context, index) {
                final file = _vaultFiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                    ),
                    title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Locked in Vault', style: TextStyle(fontSize: 11)),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('View')),
                        const PopupMenuItem(value: 'unlock', child: Text('Remove from Vault')),
                      ],
                      onSelected: (val) {
                        if (val == 'open') {
                           context.push('/pdf-viewer', extra: {
                            'path': file.vaultPath,
                            'fileName': file.fileName,
                          });
                        } else if (val == 'unlock') {
                          _unlockFile(file);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
