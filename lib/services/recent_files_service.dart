import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentFile {
  final String path;
  final String name;
  final String date;
  final String size;

  RecentFile({
    required this.path,
    required this.name,
    required this.date,
    required this.size,
  });

  Map<String, String> toJson() => {
        'path': path,
        'name': name,
        'date': date,
        'size': size,
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'] ?? '',
        name: json['name'] ?? '',
        date: json['date'] ?? '',
        size: json['size'] ?? '',
      );
}

class RecentFilesService {
  static const String _key = 'recent_files';

  static Future<List<RecentFile>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => RecentFile.fromJson(e)).toList();
  }

  static Future<void> addRecentFile(RecentFile file) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentFile> files = await getRecentFiles();
    
    // Remove if already exists to move it to top
    files.removeWhere((element) => element.path == file.path);
    files.insert(0, file);
    
    // Keep only last 20 files
    if (files.length > 20) {
      files = files.sublist(0, 20);
    }
    
    final String jsonString = jsonEncode(files.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> removeRecentFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentFile> files = await getRecentFiles();
    files.removeWhere((element) => element.path == path);
    final String jsonString = jsonEncode(files.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> pinToTop(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<RecentFile> files = await getRecentFiles();
    final index = files.indexWhere((element) => element.path == path);
    if (index != -1) {
      final file = files.removeAt(index);
      files.insert(0, file);
      final String jsonString = jsonEncode(files.map((e) => e.toJson()).toList());
      await prefs.setString(_key, jsonString);
    }
  }
}
