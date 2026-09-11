import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class DocumentSettingsService {
  static const String _boxName = 'document_settings';

  /// Saves the last read page index for a specific document.
  static Future<void> saveLastReadPage(String filePath, int pageIndex) async {
    try {
      final box = Hive.box(_boxName);
      final settings = box.get(filePath, defaultValue: <dynamic, dynamic>{}) as Map;
      final newSettings = Map<dynamic, dynamic>.from(settings);
      newSettings['lastReadPage'] = pageIndex;
      await box.put(filePath, newSettings);
    } catch (e) {
      debugPrint('Error saving last read page: $e');
    }
  }

  /// Retrieves the last read page index for a specific document.
  static int getLastReadPage(String filePath) {
    try {
      final box = Hive.box(_boxName);
      final settings = box.get(filePath, defaultValue: <dynamic, dynamic>{}) as Map;
      return settings['lastReadPage'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting last read page: $e');
      return 0;
    }
  }

  /// Adds a bookmark to a specific document.
  static Future<void> addBookmark(String filePath, int pageIndex) async {
    try {
      final box = Hive.box(_boxName);
      final settings = box.get(filePath, defaultValue: <dynamic, dynamic>{}) as Map;
      final newSettings = Map<dynamic, dynamic>.from(settings);
      final List bookmarks = newSettings['bookmarks'] ?? [];
      final newBookmarks = List<int>.from(bookmarks);
      
      if (!newBookmarks.contains(pageIndex)) {
        newBookmarks.add(pageIndex);
        newBookmarks.sort();
        newSettings['bookmarks'] = newBookmarks;
        await box.put(filePath, newSettings);
      }
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  /// Removes a bookmark from a specific document.
  static Future<void> removeBookmark(String filePath, int pageIndex) async {
    try {
      final box = Hive.box(_boxName);
      final settings = box.get(filePath, defaultValue: <dynamic, dynamic>{}) as Map;
      final newSettings = Map<dynamic, dynamic>.from(settings);
      final List bookmarks = newSettings['bookmarks'] ?? [];
      final newBookmarks = List<int>.from(bookmarks);
      
      if (newBookmarks.contains(pageIndex)) {
        newBookmarks.remove(pageIndex);
        newSettings['bookmarks'] = newBookmarks;
        await box.put(filePath, newSettings);
      }
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  /// Retrieves bookmarks for a specific document.
  static List<int> getBookmarks(String filePath) {
    try {
      final box = Hive.box(_boxName);
      final settings = box.get(filePath, defaultValue: <dynamic, dynamic>{}) as Map;
      final List bookmarks = settings['bookmarks'] ?? [];
      return List<int>.from(bookmarks);
    } catch (e) {
      debugPrint('Error getting bookmarks: $e');
      return [];
    }
  }
}
