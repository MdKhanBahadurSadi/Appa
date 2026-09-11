import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VaultFile {
  final String originalPath;
  final String vaultPath;
  final String fileName;

  VaultFile({
    required this.originalPath,
    required this.vaultPath,
    required this.fileName,
  });

  Map<String, dynamic> toMap() => {
    'originalPath': originalPath,
    'vaultPath': vaultPath,
    'fileName': fileName,
  };

  factory VaultFile.fromMap(Map<dynamic, dynamic> map) => VaultFile(
    originalPath: map['originalPath'] ?? '',
    vaultPath: map['vaultPath'] ?? '',
    fileName: map['fileName'] ?? '',
  );
}

class VaultService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _boxName = 'secure_vault';

  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the secure vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Auth error: $e');
      return false;
    }
  }

  static Future<void> moveToVault(String filePath) async {
    final box = Hive.box(_boxName);
    final fileName = p.basename(filePath);
    
    final directory = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(directory.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final vaultPath = p.join(vaultDir.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.copy(vaultPath);
      await file.delete(); // Remove original

      final vaultFile = VaultFile(
        originalPath: filePath,
        vaultPath: vaultPath,
        fileName: fileName,
      );

      await box.put(filePath, vaultFile.toMap());
    }
  }

  static Future<void> removeFromVault(String vaultPath) async {
    final box = Hive.box(_boxName);
    
    // Find the vault file entry
    String? keyToRemove;
    VaultFile? targetFile;

    for (var key in box.keys) {
      final data = box.get(key);
      final file = VaultFile.fromMap(data);
      if (file.vaultPath == vaultPath) {
        keyToRemove = key.toString();
        targetFile = file;
        break;
      }
    }

    if (targetFile != null && keyToRemove != null) {
      final file = File(vaultPath);
      if (await file.exists()) {
        await file.copy(targetFile.originalPath);
        await file.delete();
        await box.delete(keyToRemove);
      }
    }
  }

  static List<VaultFile> getVaultFiles() {
    final box = Hive.box(_boxName);
    return box.values.map((e) => VaultFile.fromMap(e)).toList();
  }
}
