import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class ChatHistoryService {
  static const String _boxName = 'chat_history';

  /// Saves a chat message for a specific document path.
  static Future<void> saveMessage({
    required String filePath,
    required String role,
    required String message,
  }) async {
    try {
      final box = Hive.box(_boxName);
      final List history = box.get(filePath, defaultValue: []) ?? [];
      
      final newList = List<Map<dynamic, dynamic>>.from(history);
      
      newList.add({
        'role': role,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      await box.put(filePath, newList);
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  /// Retrieves the full chat history for a specific document path.
  static List<Map<String, String>> getHistory(String filePath) {
    try {
      final box = Hive.box(_boxName);
      final List history = box.get(filePath, defaultValue: []) ?? [];
      
      return history.map((item) {
        final map = Map<dynamic, dynamic>.from(item as Map);
        return {
          'role': map['role']?.toString() ?? '',
          'text': map['message']?.toString() ?? map['text']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error retrieving chat history: $e');
      return [];
    }
  }

  /// Clears the chat history for a specific document path.
  static Future<void> clearHistory(String filePath) async {
    try {
      final box = Hive.box(_boxName);
      await box.delete(filePath);
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }
}
