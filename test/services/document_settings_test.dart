import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:hive/hive.dart';
import 'package:appa_pdf/services/document_settings_service.dart';

void main() {
  group('DocumentSettingsService Tests', () {
    setUp(() async {
      await setUpTestHive();
      await Hive.openBox('document_settings');
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('Should save and retrieve last read page', () async {
      const path = 'test.pdf';
      await DocumentSettingsService.saveLastReadPage(path, 5);
      expect(DocumentSettingsService.getLastReadPage(path), 5);
    });

    test('Should add and retrieve bookmarks', () async {
      const path = 'test.pdf';
      await DocumentSettingsService.addBookmark(path, 10);
      await DocumentSettingsService.addBookmark(path, 2);
      
      final bookmarks = DocumentSettingsService.getBookmarks(path);
      expect(bookmarks, [2, 10]); // Should be sorted
    });

    test('Should remove bookmarks', () async {
      const path = 'test.pdf';
      await DocumentSettingsService.addBookmark(path, 10);
      await DocumentSettingsService.removeBookmark(path, 10);
      
      final bookmarks = DocumentSettingsService.getBookmarks(path);
      expect(bookmarks.contains(10), false);
    });
  });
}
